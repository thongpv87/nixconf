#!/usr/bin/env python3
import json
import subprocess
import re

def get_sys_info():
    cpu = 0
    try:
        out = subprocess.check_output("top -bn1 | grep 'Cpu(s)'", shell=True).decode()
        m = re.search(r'(\d+[\.,]\d+)\s+id', out)
        if m:
            cpu = int(100.0 - float(m.group(1).replace(',', '.')))
    except Exception:
        pass

    ram = 0
    try:
        with open("/proc/meminfo", "r") as f:
            mem = {l.split(":")[0].strip(): int(l.split(":")[1].split()[0]) for l in f if ":" in l}
        total = mem.get("MemTotal", 1)
        avail = mem.get("MemAvailable", 0)
        ram = int(((total - avail) / total) * 100)
    except Exception:
        pass

    temp = 45
    try:
        out = subprocess.check_output("sensors 2>/dev/null", shell=True).decode()
        m = re.search(r'(Tctl|CPU|Package id \d+):\s+\+?([\d.]+)', out)
        if m:
            temp = int(float(m.group(2)))
    except Exception:
        pass

    print(json.dumps({"cpu": cpu, "ram": ram, "temp": temp}))

if __name__ == "__main__":
    get_sys_info()
