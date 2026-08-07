import urllib.request
import re

url = "https://raw.githubusercontent.com/hyprwm/Hyprland/main/src/config/ConfigManager.cpp"
try:
    resp = urllib.request.urlopen(url)
    code = resp.read().decode('utf-8')
    for i, line in enumerate(code.split('\n')):
        if "Lua config not found" in line:
            print(f"L{i}: {line.strip()}")
            
            # Print the 10 lines before it to see what path it checks
            start = max(0, i-10)
            print("\nContext:")
            for j in range(start, i+5):
                print(f"L{j}: {code.split('\n')[j]}")
            break
except Exception as e:
    print("Error:", e)
