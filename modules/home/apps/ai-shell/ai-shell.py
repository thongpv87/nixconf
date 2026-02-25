#!/usr/bin/env python3
import os
import sys
import json
import subprocess
import urllib.request
import urllib.error
from datetime import datetime

# Configuration from environment
PROVIDERS_JSON = os.environ.get("AI_PROVIDERS_JSON")
PROVIDERS_FILE = os.environ.get("AI_PROVIDERS_FILE")
CACHE_DIR = os.path.expanduser("~/.cache/ai-shell")
USAGE_FILE = os.path.join(CACHE_DIR, "usage.json")

def get_atuin_history():
    try:
        result = subprocess.run(
            ["atuin", "search", "--limit", "10", "--format", "{command}"],
            capture_output=True, text=True, check=True
        )
        return result.stdout.strip().split('\n')
    except Exception:
        return []

def call_llm(provider, prompt):
    url = provider.get("url")
    model = provider.get("model")
    key = provider.get("key")
    
    if not all([url, model, key]):
        print(f"Skipping provider {provider.get('name', 'unknown')}: missing config", file=sys.stderr)
        return None

    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {key}",
        "HTTP-Referer": "https://github.com/thongpv87/nixconf",
        "X-Title": "NixConf AI Shell"
    }
    data = {
        "model": model,
        "messages": [
            {"role": "system", "content": "You are a shell assistant. Provide only the command or completion. No prose, no markdown code blocks unless multiple lines are needed. Be concise."},
            {"role": "user", "content": prompt}
        ],
        "temperature": 0.2
    }
    
    req = urllib.request.Request(url, data=json.dumps(data).encode(), headers=headers)
    try:
        with urllib.request.urlopen(req, timeout=15) as response:
            res_data = json.loads(response.read().decode())
            return res_data['choices'][0]['message']['content'].strip()
    except urllib.error.HTTPError as e:
        if e.code == 429:
            print(f"Provider {provider.get('name')} rate limited (429)", file=sys.stderr)
        else:
            print(f"Provider {provider.get('name')} error {e.code}: {e.reason}", file=sys.stderr)
        return None
    except Exception as e:
        print(f"Provider {provider.get('name')} connection error: {e}", file=sys.stderr)
        return None

def main():
    providers = []
    if PROVIDERS_JSON:
        try:
            providers = json.loads(PROVIDERS_JSON)
        except Exception as e:
            print(f"Error parsing AI_PROVIDERS_JSON: {e}", file=sys.stderr)

    if PROVIDERS_FILE and os.path.exists(PROVIDERS_FILE):
        try:
            with open(PROVIDERS_FILE, 'r') as f:
                file_providers = json.load(f)
                if isinstance(file_providers, list):
                    providers.extend(file_providers)
                else:
                    providers.append(file_providers)
        except Exception as e:
            print(f"Error parsing AI_PROVIDERS_FILE: {e}", file=sys.stderr)

    if not providers:
        print("Error: No AI providers configured.", file=sys.stderr)
        sys.exit(1)

    # Current shell context
    buffer = " ".join(sys.argv[1:])
    history = get_atuin_history()
    
    prompt = f"Context: Current history (newest first):\n" + "\n".join(history) + f"\n\nComplete or suggest a command for this input: {buffer}"

    os.makedirs(CACHE_DIR, exist_ok=True)
    
    usage = {}
    if os.path.exists(USAGE_FILE):
        try:
            with open(USAGE_FILE, 'r') as f:
                usage = json.load(f)
        except: pass

    success = False
    for provider in providers:
        key = provider.get('key', '')
        provider_id = f"{provider.get('name')}_{key[:4]}...{key[-4:]}"
        last_failure = usage.get(provider_id, {}).get("last_failure")
        
        if last_failure:
            try:
                last_dt = datetime.fromisoformat(last_failure)
                if (datetime.now() - last_dt).total_seconds() < 300:
                    continue
            except: pass

        completion = call_llm(provider, prompt)
        if completion:
            # Clean up markdown
            if completion.startswith("```"):
                lines = completion.split('\n')
                if lines[0].startswith("```"): lines = lines[1:]
                if lines[-1].startswith("```"): lines = lines[:-1]
                completion = "\n".join(lines).strip()
            
            print(completion)
            success = True
            break
        else:
            usage[provider_id] = {"last_failure": datetime.now().isoformat()}
    
    with open(USAGE_FILE, 'w') as f:
        json.dump(usage, f)
    
    if not success:
        print("Error: All providers failed or were skipped due to recent errors.", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
