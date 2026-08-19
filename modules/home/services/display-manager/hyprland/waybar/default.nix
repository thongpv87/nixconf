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
in
{
  options.nixconf.services.display-manager.hyprland.waybar = {
    enable = mkEnableOption "Enable waybar";
  };

  config = (
    mkIf cfg.enable {
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
            };

            "clock#time" = {
              format = "{:%H:%M}";
            };

            cpu = {
              interval = 10;
              format = " {usage}%";
              tooltip = false;
            };
            memory = {
              interval = 30;
              format = "󰍛 {used:0.1f}G";
              tooltip = false;
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
              on-click = "${pkgs.pavucontrol}/bin/pavucontrol";
              tooltip = true;
            };
            network = {
              interval = 60;
              format-wifi = " {essid}";
              format-ethernet = "";
              tooltip-format = " {ifname} via {gwaddr}\nWifi: {essid} ({signalStrength}%)";
              format-linked = "";
              format-disconnected = "⚠";
              format-alt = "{ifname}: {ipaddr}/{cidr}";
              tooltip = true;
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
                "4" = "";
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
              format = "{class} {title}";
              rewrite = {
                "firefox (.*) — Mozilla Firefox" = " $1";
                "emacs (.*) – Doom Emacs(.*)" = " $1";
                "Alacritty (.*)" = " $1";
                "kitty (.*)" = " $1";
                "google-chrome (.*) - Google Chrome" = " $1";
                "chromium-browser (.*) - Chromium" = " $1";
                "microsoft-edge (.*) - Microsoft​ Edge" = " $1";
                "code-url-handler (.*) - Visual Studio Code" = "󰨞 $1";
                "org.gnome.Nautilus (.*)" = "󰉋 $1";
                "org.kde.Okular (.*)" = " $1";
                "discord (.*)" = "󰙯 $1";
                "slack (.*) - Slack" = " $1";
                "VirtualBox Machine (.*) - Oracle VM VirtualBox" = "󰆧 $1";
                "VirtualBox Manager (.*)" = "󰆧 $1";
              };
              separate-outputs = true;
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
