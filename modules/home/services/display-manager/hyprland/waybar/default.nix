{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.nixconf.services.display-manager.hyprland.waybar;
  inherit (lib)
    mkOption
    mkMerge
    mkIf
    mkDefault
    mkForce
    types
    mdDoc
    mkEnableOption
    ;

  audioSwitcherScript = pkgs.writeScriptBin "audio-output-switcher" ''
    #!${pkgs.bash}/bin/bash
    export PATH="${lib.makeBinPath [ pkgs.pipewire pkgs.wireplumber pkgs.rofi pkgs.libnotify pkgs.python3 ]}:$PATH"
    export AUDIO_SWITCHER_THEME="${./scripts/audio-switcher.rasi}"
    exec ${pkgs.python3}/bin/python3 ${./scripts/audio-output-switcher.py} "$@"
  '';

  networkManagerScript = pkgs.writeScriptBin "network-manager" ''
    #!${pkgs.bash}/bin/bash
    export PATH="${lib.makeBinPath [ pkgs.networkmanager pkgs.rofi pkgs.libnotify pkgs.kitty pkgs.python3 ]}:$PATH"
    export NETWORK_MENU_THEME="${./scripts/network-menu.rasi}"
    exec ${pkgs.python3}/bin/python3 ${./scripts/network-manager.py} "$@"
  '';

  calendarWidgetScript = pkgs.writeScriptBin "calendar-widget" ''
    #!${pkgs.bash}/bin/bash
    export PATH="${lib.makeBinPath [ pkgs.rofi pkgs.python3 ]}:$PATH"
    export CALENDAR_MENU_THEME="${./scripts/calendar-menu.rasi}"
    exec ${pkgs.python3}/bin/python3 ${./scripts/calendar-widget.py} "$@"
  '';
in
{
  options.nixconf.services.display-manager.hyprland.waybar = {
    enable = mkEnableOption "Enable waybar";
  };

  config = (
    mkIf cfg.enable {
      home.packages = [
        audioSwitcherScript
        networkManagerScript
        calendarWidgetScript
      ];

      programs.waybar = {
        enable = true;
        systemd = {
          enable = true;
          # targets = [ "hyprland-session.target" ];
          targets = [ "graphical-session.target" ];
        };
        settings = {
          mainbar = {
            layer = "top";
            # output = [ primaryDisplay ];

            spacing = 0;
            modules-left = [ "hyprland/workspaces" ];
            modules-center = [ "hyprland/window" ];
            #modules-center = [ "custom/media" ];
            modules-right = [
              "custom/arrow_system"
              "cpu"
              "memory"
              "temperature"
              "custom/arrow_hardware"
              "pulseaudio"
              "backlight"
              "custom/arrow_network"
              "network"
              "custom/arrow_date"
              "clock#date"
              "custom/arrow_time"
              "clock#time"
              "custom/arrow_battery"
              "battery"
              "custom/arrow_tray"
              "tray"
            ];

            gtk-layer-shell = true;

            "custom/arrow_system" = { format = ""; tooltip = false; };
            "custom/arrow_hardware" = { format = ""; tooltip = false; };
            "custom/arrow_network" = { format = ""; tooltip = false; };
            "custom/arrow_date" = { format = ""; tooltip = false; };
            "custom/arrow_time" = { format = ""; tooltip = false; };
            "custom/arrow_battery" = { format = ""; tooltip = false; };
            "custom/arrow_tray" = { format = ""; tooltip = false; };

            "clock#date" = {
              format = " {:%a %d %b}";
              tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
              on-click = "${calendarWidgetScript}/bin/calendar-widget";
            };

            "clock#time" = {
              format = "{:%H:%M}";
              on-click = "${calendarWidgetScript}/bin/calendar-widget";
            };

            cpu = {
              interval = 10;
              format = " {usage}%";
              tooltip = false;
              on-click = "${pkgs.kitty}/bin/kitty --class btop -e ${pkgs.btop}/bin/btop";
            };
            memory = {
              interval = 30;
              format = "󰍛 {used:0.1f}G";
              tooltip = false;
              on-click = "${pkgs.kitty}/bin/kitty --class btop -e ${pkgs.btop}/bin/btop";
            };
            temperature = {
              hwmon-path = "/sys/devices/virtual/thermal/thermal_zone0/temp";
              critical-threshold = 85;
              format = "{icon}&#8239;{temperatureC}°C";
              format-icons = [
                ""
                ""
                ""
                ""
                ""
              ];
              on-click = "${pkgs.kitty}/bin/kitty --class btop -e ${pkgs.btop}/bin/btop";
            };
            battery = {
              bat = "BAT0";
              states = {
                good = 80;
                warning = 30;
                critical = 15;
              };
              format = "{icon}&#8239;{capacity}%";
              format-charging = "󰂄&#8239;{capacity}%";
              format-plugged = "&#8239;{capacity}%";
              format-alt = "{icon} {power}W";
              format-icons = [
                ""
                ""
                ""
                ""
                ""
              ];
              tooltip = true;
              tooltip-format = "Power: {power}W\nTime: {time}";
            };
            backlight = {
              device = "acpi_video1";
              format = "{icon} {percent}%";
              format-icons = [
                "󰃚"
                "󰃞"
                "󰃟"
                "󰃠" 
              ];
              tooltip = false;
              on-scroll-up = "${pkgs.brightnessctl}/bin/brightnessctl set 2%+";
              on-scroll-down = "${pkgs.brightnessctl}/bin/brightnessctl set 1%-";
            };
            pulseaudio = {
              format = "{icon} {volume}%";
              format-bluetooth = "{icon} {volume}%";
              format-bluetooth-muted = "󰟎 {volume}%";
              format-muted = "󰖁 {volume}%";
              format-source-muted = "";
              format-icons = {
                "default" = [
                  "󰕿"
                  "󰖀"
                  "󰕾"
                ];
                headphone = "󰋋";
                hands-free = "󰋋";
                headset = "󰋎";
                phone = "";
                portable = "";
                car = "";
              };
              on-scroll-up = "${pkgs.pamixer}/bin/pamixer -i 5";
              on-scroll-down = "${pkgs.pamixer}/bin/pamixer -d 5";
              on-click-middle = "${pkgs.pamixer}/bin/pamixer --toggle-mute";
              on-click = "${audioSwitcherScript}/bin/audio-output-switcher";
              on-click-right = "${pkgs.pavucontrol}/bin/pavucontrol";
              tooltip = true;
              tooltip-format = "{desc} | {volume}%";
            };
            network = {
              interval = 60;
              format-wifi = " {essid}";
              format-ethernet = "";
              tooltip-format = " {ifname} via {gwaddr}\nWifi: {essid} ({signalStrength}%)";
              format-linked = "";
              format-disconnected = "⚠";
              tooltip = true;
              on-click = "${networkManagerScript}/bin/network-manager";
              on-click-right = "${pkgs.kitty}/bin/kitty --class nmtui -e ${pkgs.networkmanager}/bin/nmtui";
            };
            tray = {
              spacing = 10;
            };

            "custom/separator" = {
              format = "|";
              interval = "once";
              tooltip = false;
            };

            "custom/suspend" = {
              exec = "suspend-countdown";
              return-type = "json";
              format = "{}";
              tooltip = true;
            };

            "hyprland/workspaces" = {
              sort-by-name = true;
              all-outputs = true;
              format = "{icon}";
              format-icons = {
                "1" = "";
                "2" = "";
                "3" = "";
                "4" = "";
                "5" = "";
                "6" = "󰀫";
                "7" = "";
                "8" = "󰏉";
                "9" = "󰒠";
                special = "󱄅";
                urgent = "";
                focused = "";
                default = "";
              };
            };

            "hyprland/window" = {
              format = "{title}";
              icon = true;
              icon-size = 18;
              separate-outputs = true;
              rewrite = {
                # IDEs: đưa tên file lên trước project
                "(.*) - Antigravity IDE - (.*)" = "$2 — $1";
                "(.*) - Visual Studio Code - (.*)" = "$2 — $1";
                # Quy tắc tổng quát cho mọi app: tự động lọc bỏ tên app ở đuôi sau dấu gạch (- / — / – / |)
                "(.*) [-—–|] [^—–|-]+$" = "$1";
                "^$" = "";
              };
            };

            "custom/media" = {
              format = "{icon}{}";
              return-type = "json";
              format-icons = {
                Playing = " ";
                Paused = " ";
              };
              max-length = 30;
              exec = ''${pkgs.playerctl}/bin/playerctl -a metadata --format '{"text": "{{playerName}}: {{artist}} - {{markup_escape(title)}}", "tooltip": "{{playerName}} : {{markup_escape(title)}}", "alt": "{{status}}", "class": "{{status}}"}' -F'';
              on-click = "${pkgs.playerctl}/bin/playerctl play-pause";
              smooth-scrolling-threshold = 5;
              on-scroll-up = "${pkgs.playerctl}/bin/playerctl next";
              on-scroll-down = "${pkgs.playerctl}/bin/playerctl previous";
            };
            #};
          };
        };
        style = ./waybar-wal.css;
      };
    }
  );
}
