import urllib.request
import re

url = "https://raw.githubusercontent.com/hyprwm/Hyprland/main/src/config/ConfigManager.cpp"
try:
    resp = urllib.request.urlopen(url)
    code = resp.read().decode('utf-8')
    lines = code.split('\n')
    
    # search for CFG_PATH init
    for i, line in enumerate(lines):
        if "CConfigManager::init" in line or "CConfigManager::CConfigManager" in line or "void init(" in line:
            print(f"L{i}: {line.strip()}")
            for j in range(i, i+30):
                print(f"L{j}: {lines[j]}")
            break
except Exception as e:
    print("Error:", e)
