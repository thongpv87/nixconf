import urllib.request
import re

url = "https://raw.githubusercontent.com/hyprwm/Hyprland/main/src/config/ConfigManager.cpp"
try:
    resp = urllib.request.urlopen(url)
    code = resp.read().decode('utf-8')
    lines = code.split('\n')
    
    for i, line in enumerate(lines):
        if "getMainConfigPath()" in line or "ConfigManager::init(" in line:
            print(f"L{i}: {line.strip()}")
            for j in range(i, i+20):
                print(f"L{j}: {lines[j]}")
            break
except Exception as e:
    print("Error:", e)
