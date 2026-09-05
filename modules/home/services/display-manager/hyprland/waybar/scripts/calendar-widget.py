#!/usr/bin/env python3
import math
import datetime
import calendar
import subprocess
import sys
import os

CAN = ["Giáp", "Ất", "Bính", "Đinh", "Mậu", "Kỷ", "Canh", "Tân", "Nhâm", "Quý"]
CHI = ["Tý", "Sửu", "Dần", "Mão", "Thìn", "Tỵ", "Ngọ", "Mùi", "Thân", "Dậu", "Tuất", "Hợi"]

TIET_KHI = [
    "Xuân phân", "Thanh minh", "Cốc vũ", "Lập hạ", "Tiểu mãn", "Mang chủng",
    "Hạ chí", "Tiểu thử", "Đại thử", "Lập thu", "Xử thử", "Bạch lộ",
    "Thu phân", "Hàn lộ", "Sương giáng", "Lập đông", "Tiểu tuyết", "Đại tuyết",
    "Đông chí", "Tiểu hàn", "Đại hàn", "Lập xuân", "Vũ thủy", "Kinh trập"
]

HOANG_DAO = {
    "Tý": ["Tý", "Sửu", "Mão", "Ngọ", "Thân", "Dậu"],
    "Sửu": ["Dần", "Mão", "Tỵ", "Thân", "Tuất", "Hợi"],
    "Dần": ["Tý", "Sửu", "Thìn", "Tỵ", "Mùi", "Tuất"],
    "Mão": ["Tý", "Dần", "Mão", "Ngọ", "Mùi", "Dậu"],
    "Thìn": ["Dần", "Thìn", "Tỵ", "Thân", "Dậu", "Hợi"],
    "Tỵ": ["Sửu", "Thìn", "Ngọ", "Mùi", "Tuất", "Hợi"],
    "Ngọ": ["Tý", "Sửu", "Mão", "Ngọ", "Thân", "Dậu"],
    "Mùi": ["Dần", "Mão", "Tỵ", "Thân", "Tuất", "Hợi"],
    "Thân": ["Tý", "Sửu", "Thìn", "Tỵ", "Mùi", "Tuất"],
    "Dậu": ["Tý", "Dần", "Mão", "Ngọ", "Mùi", "Dậu"],
    "Tuất": ["Dần", "Thìn", "Tỵ", "Thân", "Dậu", "Hợi"],
    "Hợi": ["Sửu", "Thìn", "Ngọ", "Mùi", "Tuất", "Hợi"],
}

SOLAR_HOLIDAYS = {
    (1, 1): "Tết Dương lịch",
    (14, 2): "Lễ Tình nhân",
    (27, 2): "Ngày Thầy thuốc Việt Nam",
    (8, 3): "Quốc tế Phụ nữ",
    (26, 3): "Thành lập Đoàn TNCS HCM",
    (30, 4): "Giải phóng miền Nam",
    (1, 5): "Quốc tế Lao động",
    (7, 5): "Chiến thắng Điện Biên Phủ",
    (19, 5): "Sinh nhật Bác Hồ",
    (1, 6): "Quốc tế Thiếu nhi",
    (28, 6): "Ngày Gia đình Việt Nam",
    (27, 7): "Thương binh Liệt sĩ",
    (19, 8): "Cách mạng tháng Tám",
    (2, 9): "Quốc khánh nước CHXHCN Việt Nam",
    (10, 10): "Giải phóng Thủ đô",
    (20, 10): "Ngày Phụ nữ Việt Nam",
    (20, 11): "Ngày Nhà giáo Việt Nam",
    (22, 12): "Thành lập QĐND Việt Nam",
    (24, 12): "Lễ Giáng sinh",
}

LUNAR_HOLIDAYS = {
    (1, 1): "Mùng 1 Tết Nguyên Đán",
    (2, 1): "Mùng 2 Tết Nguyên Đán",
    (3, 1): "Mùng 3 Tết Nguyên Đán",
    (15, 1): "Tết Nguyên Tiêu",
    (3, 3): "Tết Hàn Thực",
    (10, 3): "Giỗ Tổ Hùng Vương",
    (15, 4): "Lễ Phật Đản",
    (5, 5): "Tết Đoan Ngọ",
    (15, 7): "Vu Lan & Xá tội vong nhân",
    (15, 8): "Tết Trung Thu",
    (9, 9): "Tết Trùng Cửu",
    (15, 10): "Lễ Hạ Nguyên",
    (23, 12): "Tiễn Táo Quân về trời",
    (30, 12): "Đêm Giao thừa",
}

def jd_from_date(dd, mm, yy):
    a = (14 - mm) // 12
    y = yy + 4800 - a
    m = mm + 12 * a - 3
    return dd + (153 * m + 2) // 5 + 365 * y + y // 4 - y // 100 + y // 400 - 32045

def new_moon(k):
    T = k / 1236.85
    T2 = T * T
    T3 = T2 * T
    T4 = T3 * T
    dr = math.pi / 180.0
    Jd1 = 2415020.75933 + 29.53058868 * k + 0.0001178 * T2 - 0.000000155 * T3
    Jd1 += 0.00033 * math.sin((166.56 + 132.87 * T - 0.009173 * T2) * dr)
    M = 359.2242 + 29.10535608 * k - 0.0000333 * T2 - 0.00000347 * T3
    Mpr = 306.0253 + 385.81691806 * k + 0.0107306 * T2 + 0.00001236 * T3
    F = 21.2964 + 390.67050646 * k - 0.0016528 * T2 - 0.00000239 * T3
    C1 = (0.1734 - 0.000393 * T) * math.sin(M * dr) + 0.0021 * math.sin(2 * M * dr)
    C1 -= 0.4068 * math.sin(Mpr * dr) + 0.0161 * math.sin(2 * Mpr * dr)
    C1 -= 0.0004 * math.sin(3 * Mpr * dr)
    C1 += 0.0104 * math.sin(2 * F * dr) - 0.0051 * math.sin((M + Mpr) * dr)
    C1 -= 0.0074 * math.sin((M - Mpr) * dr) + 0.0004 * math.sin((2 * F + M) * dr)
    C1 -= 0.0004 * math.sin((2 * F - M) * dr) - 0.0006 * math.sin((2 * F + Mpr) * dr)
    C1 += 0.0010 * math.sin((2 * F - Mpr) * dr) + 0.0005 * math.sin((M + 2 * Mpr) * dr)
    deltat = 0.0
    if T < -11:
        deltat = 0.001 + 0.000839 * T + 0.0002261 * T2 - 0.00000845 * T3 - 0.000000081 * T4
    else:
        deltat = -0.000078 + 0.0000784 * T + 0.00002988 * T2
    return Jd1 + C1 - deltat

def sun_longitude(jdn):
    T = (jdn - 2451545.0) / 36525.0
    T2 = T * T
    dr = math.pi / 180.0
    L0 = 280.46645 + 36000.76983 * T + 0.0003032 * T2
    M = 357.52910 + 35999.05030 * T - 0.0001559 * T2 - 0.00000048 * T * T2
    C = (1.914600 - 0.004817 * T - 0.000014 * T2) * math.sin(M * dr)
    C += (0.019993 - 0.000101 * T) * math.sin(2 * M * dr) + 0.000290 * math.sin(3 * M * dr)
    theta = L0 + C
    return math.floor((theta % 360.0) / 30.0)

def get_lunar_month_11(yy, tz=7.0):
    off = jd_from_date(31, 12, yy) - 2415021.076998695
    k = math.floor(off / 29.530588853)
    nm = new_moon(k)
    sun_long = sun_longitude(nm + 0.5 + tz / 24.0)
    if sun_long >= 9:
        nm = new_moon(k - 1)
    return math.floor(nm + 0.5 + tz / 24.0)

def get_leap_month_offset(a11, tz=7.0):
    k = math.floor((a11 - 2415021.076998695) / 29.530588853 + 0.5)
    last = 0
    i = 1
    arc = sun_longitude(new_moon(k) + 0.5 + tz / 24.0)
    while True:
        last = arc
        k += 1
        arc = sun_longitude(new_moon(k) + 0.5 + tz / 24.0)
        if arc == last:
            return i
        i += 1
        if i >= 14:
            break
    return 0

def convert_solar_to_lunar(dd, mm, yy, tz=7.0):
    jdn = jd_from_date(dd, mm, yy)
    k = math.floor((jdn - 2415021.076998695) / 29.530588853)
    month_start = new_moon(k)
    if math.floor(month_start + 0.5 + tz / 24.0) > jdn:
        month_start = new_moon(k - 1)
    a11 = get_lunar_month_11(yy, tz)
    b11 = a11
    if a11 >= jdn:
        lunar_year = yy
        a11 = get_lunar_month_11(yy - 1, tz)
    else:
        lunar_year = yy + 1
        b11 = get_lunar_month_11(yy + 1, tz)
    lunar_day = jdn - math.floor(month_start + 0.5 + tz / 24.0) + 1
    diff = math.floor((month_start - a11) / 29.0)
    leap_month_diff = get_leap_month_offset(a11, tz)
    is_leap = False
    lunar_month = diff + 11
    if diff >= leap_month_diff and leap_month_diff > 0:
        lunar_month = diff + 10
        if diff == leap_month_diff:
            is_leap = True
    if lunar_month > 12:
        lunar_month -= 12
    if lunar_month >= 11 and diff < 4:
        lunar_year -= 1
    return int(lunar_day), int(lunar_month), int(lunar_year), is_leap

def get_can_chi(dd, mm, yy, ld, lm, ly):
    jdn = jd_from_date(dd, mm, yy)
    can_year = CAN[(ly + 6) % 10]
    chi_year = CHI[(ly + 8) % 12]
    can_day = CAN[(jdn + 9) % 10]
    chi_day = CHI[(jdn + 1) % 12]
    can_month = CAN[(ly * 12 + lm + 3) % 10]
    chi_month = CHI[(lm + 1) % 12]
    return f"Ngày {can_day} {chi_day}, Tháng {can_month} {chi_month}, Năm {can_year} {chi_year}", chi_day

def get_solar_term(dd, mm, yy):
    jdn = jd_from_date(dd, mm, yy)
    T = (jdn + 0.5 - 7.0 / 24.0 - 2451545.0) / 36525.0
    T2 = T * T
    dr = math.pi / 180.0
    L0 = 280.46645 + 36000.76983 * T + 0.0003032 * T2
    M = 357.52910 + 35999.05030 * T - 0.0001559 * T2 - 0.00000048 * T * T2
    C = (1.914600 - 0.004817 * T - 0.000014 * T2) * math.sin(M * dr)
    C += (0.019993 - 0.000101 * T) * math.sin(2 * M * dr) + 0.000290 * math.sin(3 * M * dr)
    theta = (L0 + C) % 360.0
    idx = int(math.floor(theta / 15.0)) % 24
    return TIET_KHI[idx]

def build_calendar(yy, mm, now):
    is_current_month = (yy == now.year and mm == now.month)
    today_d = now.day if is_current_month else None

    lines = []
    actions = []

    # Navigation header
    prev_m = 12 if mm == 1 else mm - 1
    prev_y = yy - 1 if mm == 1 else yy
    next_m = 1 if mm == 12 else mm + 1
    next_y = yy + 1 if mm == 12 else yy

    nav_header = f"<b><span color='#9ccfd8'>◄ T{prev_m:02d}</span>      <span color='#f6c177' size='large'>THÁNG {mm:02d} / {yy}</span>      <span color='#9ccfd8'>T{next_m:02d} ►</span></b>"
    lines.append(nav_header)
    actions.append({"type": "ignore"})

    if is_current_month:
        weekday_str = ["Thứ Hai", "Thứ Ba", "Thứ Tư", "Thứ Năm", "Thứ Sáu", "Thứ Bảy", "Chủ Nhật"][now.weekday()]
        ld, lm, ly, is_leap = convert_solar_to_lunar(now.day, mm, yy)
        can_chi_str, chi_day = get_can_chi(now.day, mm, yy, ld, lm, ly)
        tiet_khi = get_solar_term(now.day, mm, yy)

        lines.append(f"<b>🌟 <span color='#f6c177'>{weekday_str}</span>, {now.day:02d}/{mm:02d}/{yy}  •  <span color='#9ccfd8'>{ld:02d}/{lm:02d}{' (N)' if is_leap else ''} Âm lịch</span></b>")
        actions.append({"type": "ignore"})

        lines.append(f"🗓  <span color='#ebbcba'>{can_chi_str}</span>")
        actions.append({"type": "ignore"})

        lines.append(f"🌿 <span color='#908caa'>Tiết khí:</span> <span color='#a9dc76'>{tiet_khi}</span>")
        actions.append({"type": "ignore"})

        # Check next upcoming holiday
        upcoming_holiday = ""
        for days_ahead in range(60):
            check_date = now + datetime.timedelta(days=days_ahead)
            c_dd, c_mm, c_yy = check_date.day, check_date.month, check_date.year
            c_ld, c_lm, c_ly, _ = convert_solar_to_lunar(c_dd, c_mm, c_yy)

            if (c_ld, c_lm) in LUNAR_HOLIDAYS:
                name = LUNAR_HOLIDAYS[(c_ld, c_lm)]
                if days_ahead == 0:
                    upcoming_holiday = f"Hôm nay: {name}!"
                else:
                    upcoming_holiday = f"Sắp tới: {name} • {c_dd:02d}/{c_mm:02d} • còn {days_ahead} ngày"
                break

            if (c_dd, c_mm) in SOLAR_HOLIDAYS:
                name = SOLAR_HOLIDAYS[(c_dd, c_mm)]
                if days_ahead == 0:
                    upcoming_holiday = f"Hôm nay: {name}!"
                else:
                    upcoming_holiday = f"Sắp tới: {name} • {c_dd:02d}/{c_mm:02d} • còn {days_ahead} ngày"
                break

        if upcoming_holiday:
            lines.append(f"🎉 <span color='#eb6f92'>{upcoming_holiday}</span>")
            actions.append({"type": "ignore"})
    else:
        f_ld, f_lm, f_ly, f_leap = convert_solar_to_lunar(1, mm, yy)
        lines.append(f"<b>🗓  Đầu tháng {mm:02d}/{yy}: <span color='#9ccfd8'>{f_ld:02d}/{f_lm:02d} Âm lịch</span></b>")
        actions.append({"type": "ignore"})

    lines.append("<span color='#524f67'>──────────────────────────────────────────────────────</span>")
    actions.append({"type": "ignore"})
    lines.append("<span color='#6e6a86'>      │</span><span color='#9ccfd8' weight='bold'>  T2    T3    T4    T5    T6  </span><span color='#eb6f92' weight='bold'>  T7    CN  </span>")
    actions.append({"type": "ignore"})
    lines.append("<span color='#524f67'>──────┼───────────────────────────────────────────────</span>")
    actions.append({"type": "ignore"})

    cal = calendar.monthcalendar(yy, mm)
    for idx, week in enumerate(cal):
        s_cells = []
        l_cells = []
        for col, day in enumerate(week):
            if day == 0:
                s_cells.append("      ")
                l_cells.append("      ")
            else:
                c_ld, c_lm, _, _ = convert_solar_to_lunar(day, mm, yy)
                
                # Solar formatting
                if day == today_d:
                    s_cells.append(f"<span background='#eb6f92' color='#191724' weight='bold'>  {day:02d}  </span>")
                elif col >= 5:
                    s_cells.append(f"<span color='#ebbcba'>  {day:02d}  </span>")
                else:
                    s_cells.append(f"<span color='#e0def4'>  {day:02d}  </span>")
                
                # Lunar formatting
                if day == today_d:
                    if c_ld == 1:
                        l_cells.append(f"<span background='#f6c177' color='#191724' weight='bold'> 1/{c_lm:<2} </span>")
                    elif c_ld == 15:
                        l_cells.append(f"<span background='#f6c177' color='#191724' weight='bold'>  15* </span>")
                    else:
                        l_cells.append(f"<span background='#f6c177' color='#191724' weight='bold'>  {c_ld:02d}  </span>")
                elif c_ld == 1:
                    l_cells.append(f"<span color='#f6c177' weight='bold'> 1/{c_lm:<2} </span>")
                elif c_ld == 15:
                    l_cells.append(f"<span color='#f6c177' weight='bold'>  15* </span>")
                else:
                    l_cells.append(f"<span color='#908caa'>  {c_ld:02d}  </span>")

        lines.append("<span color='#9ccfd8' weight='bold'>  DL  │</span>" + "".join(s_cells))
        actions.append({"type": "ignore"})
        lines.append("<span color='#f6c177' weight='bold'>  ÂL  │</span>" + "".join(l_cells))
        actions.append({"type": "ignore"})
        if idx < len(cal) - 1:
            lines.append("<span color='#403d52'>┄┄┄┄┄┄┼┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄</span>")
            actions.append({"type": "ignore"})

    # Holidays in this month
    this_month_holidays = []
    for day in range(1, 32):
        try:
            d_obj = datetime.date(yy, mm, day)
        except ValueError:
            break
        # Solar
        if (day, mm) in SOLAR_HOLIDAYS:
            this_month_holidays.append(f"• <span color='#9ccfd8'>{day:02d}/{mm:02d} DL</span>: {SOLAR_HOLIDAYS[(day, mm)]}")
        # Lunar
        c_ld, c_lm, _, _ = convert_solar_to_lunar(day, mm, yy)
        if (c_ld, c_lm) in LUNAR_HOLIDAYS:
            this_month_holidays.append(f"• <span color='#f6c177'>{day:02d}/{mm:02d} DL ({c_ld}/{c_lm} ÂL)</span>: {LUNAR_HOLIDAYS[(c_ld, c_lm)]}")

    if this_month_holidays:
        lines.append("<span color='#524f67'>──────────── CÁC NGÀY LỄ TRONG THÁNG ─────────────</span>")
        actions.append({"type": "ignore"})
        for h in this_month_holidays:
            lines.append(f"  {h}")
            actions.append({"type": "ignore"})

    # Navigation actions at bottom
    lines.append("<span color='#524f67'>──────────────────────────────────────────────────────</span>")
    actions.append({"type": "ignore"})
    lines.append("   <span color='#9ccfd8'>◀ Tháng trước</span>")
    actions.append({"type": "prev"})
    lines.append("   <span color='#9ccfd8'>▶ Tháng sau</span>")
    actions.append({"type": "next"})
    if not is_current_month:
        lines.append("   <span color='#f6c177'>󰸗 Quay lại hôm nay</span>")
        actions.append({"type": "today"})

    return lines, actions

def main():
    # Toggle off if already running
    try:
        out = subprocess.check_output(["pgrep", "-x", "rofi"]).decode("utf-8").split()
        if out:
            subprocess.run(["pkill", "-x", "rofi"])
            sys.exit(0)
    except Exception:
        pass

    now = datetime.datetime.now()
    cur_yy = now.year
    cur_mm = now.month

    theme_path = os.environ.get("CALENDAR_MENU_THEME")
    if not theme_path or not os.path.exists(theme_path):
        script_dir = os.path.dirname(os.path.realpath(__file__))
        cand = os.path.join(script_dir, "calendar-menu.rasi")
        if os.path.exists(cand):
            theme_path = cand

    while True:
        lines, actions = build_calendar(cur_yy, cur_mm, now)

        rofi_cmd = [
            "rofi",
            "-dmenu",
            "-markup-rows",
            "-format", "i",
            "-p", f"Lịch {cur_mm:02d}/{cur_yy}",
            "-selected-row", "0",
            "-hover-select",
            "-me-select-entry", "",
            "-me-accept-entry", "MousePrimary",
            "-kb-move-char-back", "Control+b",
            "-kb-move-char-forward", "Control+f",
            "-kb-custom-1", "Left",
            "-kb-custom-2", "Right",
            "-m", "-5",
        ]
        if theme_path and os.path.exists(theme_path):
            rofi_cmd.extend(["-theme", theme_path])

        res = subprocess.run(rofi_cmd, input="\n".join(lines), text=True, capture_output=True)

        # Left arrow: previous month
        if res.returncode == 10:
            cur_mm -= 1
            if cur_mm < 1:
                cur_mm = 12
                cur_yy -= 1
            continue

        # Right arrow: next month
        elif res.returncode == 11:
            cur_mm += 1
            if cur_mm > 12:
                cur_mm = 1
                cur_yy += 1
            continue

        # Selected row with mouse/enter
        elif res.returncode == 0:
            raw_out = res.stdout.strip()
            if not raw_out:
                break
            try:
                idx = int(raw_out)
                act = actions[idx]
            except (ValueError, IndexError):
                break

            act_type = act.get("type")
            if act_type == "prev":
                cur_mm -= 1
                if cur_mm < 1:
                    cur_mm = 12
                    cur_yy -= 1
                continue
            elif act_type == "next":
                cur_mm += 1
                if cur_mm > 12:
                    cur_mm = 1
                    cur_yy += 1
                continue
            elif act_type == "today":
                cur_yy = now.year
                cur_mm = now.month
                continue
            else:
                break
        else:
            # Esc or click outside -> exit
            break

if __name__ == "__main__":
    main()
