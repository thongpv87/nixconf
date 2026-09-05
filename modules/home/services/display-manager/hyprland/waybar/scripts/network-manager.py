#!/usr/bin/env python3
import subprocess
import sys
import os

def run_cmd(cmd):
    try:
        return subprocess.check_output(cmd, stderr=subprocess.DEVNULL).decode('utf-8')
    except Exception:
        return ""

def get_signal_icon(signal_str):
    try:
        sig = int(signal_str)
    except Exception:
        sig = 0
    if sig >= 75:
        return "󰤨"
    elif sig >= 50:
        return "󰤥"
    elif sig >= 25:
        return "󰤢"
    elif sig > 0:
        return "󰤟"
    return "󰤯"

def notify(title, msg, icon="network-wireless"):
    subprocess.run(["notify-send", "-u", "low", "-t", "2500", "-i", icon, title, msg], check=False)

def get_wifi_interface():
    out = run_cmd(["nmcli", "-t", "-f", "DEVICE,TYPE", "device"])
    for line in out.splitlines():
        parts = line.split(":")
        if len(parts) >= 2 and parts[1] == "wifi":
            return parts[0]
    return ""

def main():
    # Toggle off if already running
    try:
        out = subprocess.check_output(["pgrep", "-x", "rofi"]).decode("utf-8").split()
        if out:
            subprocess.run(["pkill", "-x", "rofi"])
            sys.exit(0)
    except Exception:
        pass

    wifi_power = run_cmd(["nmcli", "radio", "wifi"]).strip().lower()

    theme_path = os.environ.get("NETWORK_MENU_THEME")
    if not theme_path or not os.path.exists(theme_path):
        script_dir = os.path.dirname(os.path.realpath(__file__))
        cand = os.path.join(script_dir, "network-menu.rasi")
        if os.path.exists(cand):
            theme_path = cand

    rofi_cmd_base = [
        "rofi",
        "-dmenu",
        "-markup-rows",
        "-format", "i",
        "-selected-row", "2",
        "-hover-select",
        "-me-select-entry", "",
        "-me-accept-entry", "MousePrimary",
        "-m", "-5",
    ]
    if theme_path and os.path.exists(theme_path):
        rofi_cmd_base.extend(["-theme", theme_path])

    actions = []
    lines = []

    lines.append("<span color='#9ccfd8' weight='bold'>   QUẢN LÝ MẠNG WI-FI</span>")
    actions.append({"type": "ignore"})

    lines.append("<span color='#524f67'>──────────────────────────────────────────</span>")
    actions.append({"type": "ignore"})

    if wifi_power != "enabled":
        lines.append("󰤨   <span color='#9ccfd8' weight='bold'>Bật Wi-Fi</span>")
        actions.append({"type": "toggle_power", "val": "on"})
        lines.append("󱛄   <span color='#c4a7e7'>Cấu hình mạng nâng cao</span>")
        actions.append({"type": "nmtui"})
    else:
        # Get active wifi info
        active_raw = run_cmd(["nmcli", "-t", "-f", "active,ssid,signal,security", "device", "wifi"])
        active_ssid = ""
        active_signal = ""
        active_security = ""
        for line in active_raw.splitlines():
            parts = line.split(":")
            if len(parts) >= 4 and parts[0] == "yes":
                active_ssid = parts[1]
                active_signal = parts[2]
                active_security = parts[3] if parts[3] else "Open"
                break

        if active_ssid:
            icon = get_signal_icon(active_signal)
            lines.append(f"● <span color='#9ccfd8' weight='bold'>{icon}  {active_ssid}</span>  <span color='#f6c177'>{active_signal}%</span>  <span color='#a6e3a1'>• Đang kết nối</span>")
            actions.append({"type": "current_info", "ssid": active_ssid})

            lines.append(f"   <span color='#eb6f92'>󰅛</span>  <span color='#eb6f92'>Ngắt kết nối {active_ssid}</span>")
            actions.append({"type": "disconnect", "ssid": active_ssid})

        # Get list of saved Wi-Fi connection profiles
        saved_conns_raw = run_cmd(["nmcli", "-t", "-f", "NAME,TYPE", "connection", "show"])
        saved_ssids = set()
        for s_line in saved_conns_raw.splitlines():
            s_parts = s_line.split(":")
            if len(s_parts) >= 2 and s_parts[1] == "802-11-wireless":
                saved_ssids.add(s_parts[0])

        # Scan available networks
        scan_raw = run_cmd(["nmcli", "-t", "-f", "active,ssid,signal,security", "device", "wifi", "list", "--rescan", "no"])
        seen_ssids = set()
        if active_ssid:
            seen_ssids.add(active_ssid)

        scanned_saved = []
        scanned_other = []
        for line in scan_raw.splitlines():
            parts = line.split(":")
            if len(parts) >= 4:
                ssid = parts[1].strip()
                if not ssid or ssid in seen_ssids:
                    continue
                seen_ssids.add(ssid)
                signal = parts[2]
                security = parts[3] if parts[3] else "Open"
                icon = get_signal_icon(signal)
                if ssid in saved_ssids:
                    scanned_saved.append((ssid, signal, security, icon))
                else:
                    scanned_other.append((ssid, signal, security, icon))

        # 1. Saved networks in range (known password)
        if scanned_saved:
            lines.append("<span color='#f6c177' size='small'>─── MẠNG ĐÃ LƯU ────────────────────────────</span>")
            actions.append({"type": "ignore"})
            for ssid, signal, security, icon in scanned_saved:
                lines.append(f"   <span color='#f6c177'>{icon}</span>  <span color='#f6c177' weight='bold'>{ssid}</span>  <span color='#908caa'>{signal}%</span>")
                actions.append({
                    "type": "connect",
                    "ssid": ssid,
                    "security": security
                })

        # 2. Other available networks (unknown / open)
        if scanned_other:
            lines.append("<span color='#6e6a86' size='small'>─── MẠNG KHẢ DỤNG KHÁC ─────────────────────</span>")
            actions.append({"type": "ignore"})
            for ssid, signal, security, icon in scanned_other:
                sec_badge = "Mở" if security == "Open" else security
                lines.append(f"   <span color='#9ccfd8'>{icon}</span>  <span color='#e0def4'>{ssid}</span>  <span color='#6e6a86'>{signal}% • {sec_badge}</span>")
                actions.append({
                    "type": "connect",
                    "ssid": ssid,
                    "security": security
                })

        # 3. Actions / tools at the bottom
        lines.append("<span color='#524f67'>────────────────────────────────────────────</span>")
        actions.append({"type": "ignore"})

        lines.append("   <span color='#9ccfd8'>󰑐</span>  <span color='#e0def4'>Quét lại mạng Wi-Fi</span>")
        actions.append({"type": "refresh"})

        lines.append("   <span color='#ebbcba'>󰤮</span>  <span color='#e0def4'>Tắt Wi-Fi</span>")
        actions.append({"type": "toggle_power", "val": "off"})

        lines.append("   <span color='#c4a7e7'>󱛄</span>  <span color='#e0def4'>Cấu hình mạng nâng cao</span>")
        actions.append({"type": "nmtui"})

    rofi_input = "\n".join(lines)
    try:
        res = subprocess.run(
            rofi_cmd_base,
            input=rofi_input,
            text=True,
            capture_output=True
        )
    except FileNotFoundError:
        print("rofi not found.")
        sys.exit(1)

    raw_out = res.stdout.strip()
    if not raw_out:
        sys.exit(0)

    try:
        idx = int(raw_out)
        chosen = actions[idx]
    except (ValueError, IndexError):
        sys.exit(0)

    action_type = chosen.get("type")
    if action_type == "ignore" or action_type == "current_info":
        sys.exit(0)

    if action_type == "toggle_power":
        val = chosen.get("val", "on")
        subprocess.run(["nmcli", "radio", "wifi", val], check=False)
        notify("Wi-Fi", f"Đã {'bật' if val == 'on' else 'tắt'} Wi-Fi")

    elif action_type == "refresh":
        notify("Wi-Fi", "Đang quét các mạng lân cận...")
        subprocess.run(["nmcli", "device", "wifi", "rescan"], check=False)
        # Re-execute self to show updated list
        os.execv(sys.executable, [sys.executable] + sys.argv)

    elif action_type == "nmtui":
        subprocess.Popen(["kitty", "--class", "nmtui", "-e", "nmtui"])

    elif action_type == "disconnect":
        ssid = chosen.get("ssid", "")
        subprocess.run(["nmcli", "connection", "down", "id", ssid], check=False)
        notify("Wi-Fi", f"Đã ngắt kết nối khỏi {ssid}")

    elif action_type == "connect":
        ssid = chosen.get("ssid", "")
        security = chosen.get("security", "")

        # Check if connection profile is already saved
        saved_conns = run_cmd(["nmcli", "-t", "-f", "NAME", "connection", "show"]).splitlines()
        if ssid in saved_conns:
            notify("Wi-Fi", f"Đang kết nối tới {ssid}...")
            ret = subprocess.run(["nmcli", "connection", "up", "id", ssid], capture_output=True)
            if ret.returncode == 0:
                notify("Wi-Fi", f"Kết nối thành công tới {ssid}!")
            else:
                notify("Wi-Fi", f"Lỗi kết nối tới {ssid}: {ret.stderr.decode('utf-8')[:100]}")
        else:
            # Need password if secured
            if security and security != "Open":
                # Prompt password in rofi
                pwd_cmd = ["rofi", "-dmenu", "-password", "-p", f"Mật khẩu cho {ssid}"]
                if theme_path and os.path.exists(theme_path):
                    # We can use rofi with inputbar enabled for password prompt
                    pwd_cmd.extend(["-theme-str", "mainbox { children: [ inputbar ]; }"])
                try:
                    pwd_res = subprocess.run(pwd_cmd, input="", text=True, capture_output=True)
                    password = pwd_res.stdout.strip()
                except Exception:
                    password = ""

                if not password:
                    sys.exit(0)

                notify("Wi-Fi", f"Đang kết nối tới {ssid}...")
                ret = subprocess.run(["nmcli", "device", "wifi", "connect", ssid, "password", password], capture_output=True)
                if ret.returncode == 0:
                    notify("Wi-Fi", f"Đã kết nối thành công tới {ssid}!")
                else:
                    notify("Wi-Fi", f"Không thể kết nối tới {ssid}: {ret.stderr.decode('utf-8')[:100]}")
            else:
                # Open network
                notify("Wi-Fi", f"Đang kết nối tới {ssid}...")
                ret = subprocess.run(["nmcli", "device", "wifi", "connect", ssid], capture_output=True)
                if ret.returncode == 0:
                    notify("Wi-Fi", f"Đã kết nối thành công tới {ssid}!")
                else:
                    notify("Wi-Fi", f"Không thể kết nối tới {ssid}: {ret.stderr.decode('utf-8')[:100]}")

if __name__ == "__main__":
    main()
