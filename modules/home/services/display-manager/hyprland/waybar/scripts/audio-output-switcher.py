#!/usr/bin/env python3
import subprocess
import json
import sys
import os

def run_cmd(cmd):
    try:
        return subprocess.check_output(cmd, stderr=subprocess.DEVNULL).decode('utf-8')
    except Exception:
        return ""

def get_default_sink_name():
    meta = run_cmd(["pw-metadata", "-n", "default", "0", "default.audio.sink"])
    for line in meta.splitlines():
        if "default.audio.sink" in line:
            try:
                val_str = line.split("value:")[1].split("type:")[0].strip().strip("'")
                return json.loads(val_str).get("name", "")
            except Exception:
                pass
    return ""

def get_sinks():
    try:
        data = json.loads(run_cmd(["pw-dump", "Node"]))
    except Exception:
        return []

    sinks = []
    default_sink_name = get_default_sink_name()

    for item in data:
        props = item.get("info", {}).get("props", {})
        if props.get("media.class") != "Audio/Sink":
            continue

        node_id = item.get("id")
        name = props.get("node.name", "")
        desc = props.get("node.description", name)
        form_factor = props.get("device.form-factor", "")

        is_default = (name == default_sink_name)

        # Determine icon & category
        if "bluez" in name or form_factor in ["headphone", "headset"] or "XM" in desc or "Bluetooth" in desc:
            icon = "󰋋"
            kind = "bluetooth"
            friendly_desc = desc
        elif "analog-stereo" in name or form_factor == "speaker" or "Speaker" in desc:
            icon = "󰓃"
            kind = "speaker"
            friendly_desc = "Laptop Speakers / Analog"
        elif "pro-output" in name or "HDMI" in desc or "DisplayPort" in desc:
            icon = "󰡁"
            kind = "hdmi"
            port = name.split(".")[-1] if "." in name else ""
            friendly_desc = f"HDMI / Display Audio {port}" if port else desc
        else:
            icon = "󰕾"
            kind = "other"
            friendly_desc = desc

        # Fetch current volume
        vol_str = ""
        try:
            vol_out = run_cmd(["wpctl", "get-volume", str(node_id)]).strip()
            parts = vol_out.split()
            if len(parts) >= 2:
                vol_pct = int(float(parts[1]) * 100)
                vol_str = f"{vol_pct}%"
                if "[MUTED]" in vol_out:
                    vol_str += " • Tắt tiếng"
        except Exception:
            pass

        sinks.append({
            "id": node_id,
            "name": name,
            "desc": friendly_desc,
            "raw_desc": desc,
            "icon": icon,
            "kind": kind,
            "volume": vol_str,
            "is_default": is_default,
        })

    # Sort: default first, then bluetooth, then speaker, then hdmi/other
    kind_priority = {"bluetooth": 1, "speaker": 2, "other": 3, "hdmi": 4}
    sinks.sort(key=lambda x: (not x["is_default"], kind_priority.get(x["kind"], 5), x["desc"]))
    return sinks

def clear_active_stream_targets():
    """Ensure all currently playing applications immediately follow the new default sink."""
    try:
        dump = json.loads(run_cmd(["pw-dump"]))
        for item in dump:
            props = item.get("info", {}).get("props", {})
            if props.get("media.class") == "Stream/Output/Audio":
                s_id = str(item.get("id"))
                subprocess.run(["pw-metadata", "-n", "default", "-d", s_id, "target.object"], stderr=subprocess.DEVNULL)
                subprocess.run(["pw-metadata", "-n", "default", "-d", s_id, "target.node"], stderr=subprocess.DEVNULL)
    except Exception:
        pass

def main():
    # Toggle off if already running
    try:
        out = subprocess.check_output(["pgrep", "-x", "rofi"]).decode("utf-8").split()
        if out:
            subprocess.run(["pkill", "-x", "rofi"])
            sys.exit(0)
    except Exception:
        pass

    sinks = get_sinks()
    if not sinks:
        print("No audio output devices found.")
        sys.exit(1)

    lines = []
    actions = []

    lines.append("<span color='#f6c177' weight='bold'>🔊 THIẾT BỊ PHÁT ÂM THANH</span>")
    actions.append({"type": "ignore"})

    lines.append("<span color='#524f67'>──────────────────────────────────────────────────────</span>")
    actions.append({"type": "ignore"})

    default_row = 2
    for idx, s in enumerate(sinks):
        vol_str = s['volume'] if s["volume"] else ""
        if s["is_default"]:
            default_row = 2 + idx
            lines.append(f"● <span color='#9ccfd8' weight='bold'>{s['icon']}  {s['desc']}</span>  <span color='#eb6f92'><b>{vol_str}</b></span>  <span background='#31748f' color='#191724' weight='bold'> ĐANG DÙNG </span>")
        else:
            lines.append(f"   <span color='#ebbcba'>{s['icon']}</span>  <span color='#e0def4'>{s['desc']}</span>  <span color='#6e6a86'>{vol_str}</span>")
        actions.append({"type": "sink", "sink": s})

    lines.append("<span color='#524f67'>──────────────────────────────────────────────────────</span>")
    actions.append({"type": "ignore"})

    lines.append("󰍰  <span color='#c4a7e7'>Cài đặt âm thanh nâng cao</span>")
    actions.append({"type": "pavucontrol"})

    rofi_input = "\n".join(lines)

    # Locate theme
    theme_path = os.environ.get("AUDIO_SWITCHER_THEME")
    if not theme_path or not os.path.exists(theme_path):
        script_dir = os.path.dirname(os.path.realpath(__file__))
        candidate = os.path.join(script_dir, "audio-switcher.rasi")
        if os.path.exists(candidate):
            theme_path = candidate

    rofi_cmd = [
        "rofi",
        "-dmenu",
        "-markup-rows",
        "-format", "i",                  # Return row index 0, 1, 2...
        "-selected-row", str(default_row),
        "-hover-select",
        "-me-select-entry", "",
        "-me-accept-entry", "MousePrimary",
        "-m", "-5",
    ]
    if theme_path and os.path.exists(theme_path):
        rofi_cmd.extend(["-theme", theme_path])

    try:
        res = subprocess.run(
            rofi_cmd,
            input=rofi_input,
            text=True,
            capture_output=True
        )
    except FileNotFoundError:
        print("rofi not found.")
        sys.exit(1)

    selected_raw = res.stdout.strip()
    if not selected_raw:
        # Cancelled (e.g. Esc or clicked outside)
        sys.exit(0)

    try:
        row_idx = int(selected_raw)
        act = actions[row_idx]
    except (ValueError, IndexError):
        sys.exit(0)

    if act["type"] == "ignore":
        sys.exit(0)
    elif act["type"] == "pavucontrol":
        subprocess.Popen(["pavucontrol"])
        sys.exit(0)
    elif act["type"] == "sink":
        chosen = act["sink"]
        node_id = chosen["id"]

        # 1. Set default sink in wireplumber
        subprocess.run(["wpctl", "set-default", str(node_id)], check=False)

        # 2. Ensure WirePlumber does not pin per-application targets
        subprocess.run(["wpctl", "settings", "node.stream.restore-target", "false"], check=False)

        # 3. Clear explicit targets from active streams so they immediately move over
        clear_active_stream_targets()

    # 4. Notify user
    notify_icon = "audio-headphones" if chosen["kind"] == "bluetooth" else "audio-speakers"
    vol_info = f" ({chosen['volume']})" if chosen["volume"] else ""
    subprocess.run([
        "notify-send",
        "-u", "low",
        "-t", "2000",
        "-i", notify_icon,
        "Audio Output Switched",
        f"{chosen['icon']} {chosen['raw_desc']}{vol_info}"
    ], check=False)

if __name__ == "__main__":
    main()
