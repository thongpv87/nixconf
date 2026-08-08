#!/usr/bin/env python3
import json
import urllib.request
import datetime
import sys

def fetch_json(url):
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(req, timeout=5) as resp:
        return json.loads(resp.read().decode("utf-8"))

def main():
    lat, lon = 21.0285, 105.8542 # default Hanoi
    try:
        geo = fetch_json("http://ip-api.com/json/")
        if geo.get("status") == "success":
            lat = geo.get("lat", lat)
            lon = geo.get("lon", lon)
    except Exception:
        pass

    url = f"https://api.open-meteo.com/v1/forecast?latitude={lat}&longitude={lon}&current=temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,wind_speed_10m&hourly=temperature_2m,weather_code&daily=weather_code,temperature_2m_max,temperature_2m_min,apparent_temperature_max,precipitation_probability_max,wind_speed_10m_max&timezone=auto"

    try:
        data = fetch_json(url)
    except Exception as e:
        sys.exit(1)

    def get_wmo_info(code):
        c = int(code or 0)
        if c == 0:
            return ("", "#f9e2af", "Clear Sky")
        elif c in [1, 2, 3]:
            return ("", "#bac2de", "Cloudy")
        elif c in [45, 48]:
            return ("󰖑", "#84afdb", "Foggy")
        elif c in [51, 53, 55, 61, 63, 65, 80, 81, 82]:
            return ("󰖗", "#74c7ec", "Rainy")
        elif c in [71, 73, 75, 77, 85, 86]:
            return ("", "#cdd6f4", "Snowy")
        elif c in [95, 96, 99]:
            return ("", "#f9e2af", "Thunderstorm")
        return ("", "#bac2de", "Unknown")

    cur = data.get("current", {})
    cur_code = cur.get("weather_code", 0)
    cur_icon, cur_hex, _ = get_wmo_info(cur_code)
    cur_t_val = cur.get("temperature_2m", 0.0)
    cur_temp = f"{cur_t_val:.1f}"

    daily = data.get("daily", {})
    time_list = daily.get("time", [])
    max_list = daily.get("temperature_2m_max", [])
    min_list = daily.get("temperature_2m_min", [])
    feels_list = daily.get("apparent_temperature_max", [])
    pop_list = daily.get("precipitation_probability_max", [])
    wind_list = daily.get("wind_speed_10m_max", [])
    code_list = daily.get("weather_code", [])

    hourly = data.get("hourly", {})
    h_time = hourly.get("time", [])
    h_temp = hourly.get("temperature_2m", [])
    h_code = hourly.get("weather_code", [])

    forecast = []

    for i in range(min(5, len(time_list))):
        dt_str = time_list[i]
        dt = datetime.datetime.strptime(dt_str, "%Y-%m-%d")
        
        code = code_list[i] if i < len(code_list) else 0
        icon, hex_clr, desc = get_wmo_info(code)
        
        day_hourly = []
        for j in range(len(h_time)):
            if h_time[j].startswith(dt_str):
                h_dt = datetime.datetime.strptime(h_time[j], "%Y-%m-%dT%H:%M")
                h_ic, h_hx, _ = get_wmo_info(h_code[j])
                ht_val = h_temp[j]
                day_hourly.append({
                    "time": h_dt.strftime("%H:%M"),
                    "temp": f"{ht_val:.1f}",
                    "icon": h_ic,
                    "hex": h_hx
                })
                
        max_val = max_list[i] if i < len(max_list) else 0.0
        min_val = min_list[i] if i < len(min_list) else 0.0
        feels_val = feels_list[i] if i < len(feels_list) else 0.0
        wind_val = wind_list[i] if i < len(wind_list) else 0.0
        pop_val = pop_list[i] if i < len(pop_list) else 0.0

        forecast.append({
            "id": str(i),
            "day": dt.strftime("%a"),
            "day_full": dt.strftime("%A"),
            "date": dt.strftime("%d %b"),
            "max": f"{max_val:.1f}",
            "min": f"{min_val:.1f}",
            "feels_like": f"{feels_val:.1f}",
            "wind": str(round(wind_val)),
            "humidity": str(cur.get("relative_humidity_2m", 75)),
            "pop": str(round(pop_val)),
            "icon": icon,
            "hex": hex_clr,
            "desc": desc,
            "hourly": day_hourly
        })

    out = {
        "current_temp": cur_temp,
        "current_icon": cur_icon,
        "current_hex": cur_hex,
        "forecast": forecast
    }

    print(json.dumps(out))

if __name__ == "__main__":
    main()
