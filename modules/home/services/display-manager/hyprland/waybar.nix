{ config, pkgs, lib, ... }:
let
  cfg = config.nixconf.services.display-manager.hyprland.waybar;
  inherit (lib)
    mkOption mkMerge mkIf mkDefault mkForce types mdDoc mkEnableOption;
in {
  options.nixconf.services.display-manager.hyprland.waybar = {
    enable = mkEnableOption "Enable waybar";
  };

  config = mkIf cfg.enable {
    programs.waybar = {
      enable = true;
      settings = {
        mainbar = {
          layer = "top";
          # output = [ primaryDisplay ];

          modules-left = [ "hyprland/workspaces" ];
          modules-center = [ "hyprland/window" ];
          #modules-center = [ "custom/media" ];
          modules-right = [
            "cpu"
            "custom/separator"
            "memory"
            "custom/separator"
            "temperature"
            "custom/separator"
            "battery"
            "custom/separator"
            "backlight"
            "custom/separator"
            "pulseaudio"
            "custom/separator"
            "network"
            "custom/separator"
            "clock"
            "custom/separator"
            "idle_inhibitor"
            "custom/separator"
            "tray"
          ];

          gtk-layer-shell = true;
          clock = {
            format = "{:%a %d %b %H:%M}";
            tooltip-format = ''
              <big>{:%Y %B}</big>
              <tt><small>{calendar}</small></tt>'';
          };

          cpu = {
            interval = 10;
            format = "&#8239;{usage}%";
            tooltip = false;
          };
          memory = {
            interval = 30;
            format = " {used:0.1f}G/{total:0.1f}G";
            tooltip = false;
          };
          temperature = {
            hwmon-path = "/sys/class/hwmon/hwmon4/temp1_input";
            critical-threshold = 85;
            format = "{icon}&#8239;{temperatureC}°C";
            format-icons = [ "" "" "" "" "" ];
          };
          battery = {
            bat = "BAT0";
            states = {
              good = 80;
              warning = 30;
              critical = 15;
            };
            format = "{icon}&#8239;{capacity}";
            format-charging = "󰂄&#8239;{capacity}";
            format-plugged = "&#8239;{capacity}";
            format-alt = "{icon} {time}";
            format-icons = [ "" "" "" "" "" ];
            tooltip = true;
            tooltip-format = "Power {power}W - {timeTo}";
          };
          backlight = {
            device = "acpi_video1";
            format = "{icon}&#8239;{percent}%";
            format-icons = [ "" "" ];
            tooltip = false;
            #format-icons = [ "" "" ];
            on-scroll-up = "${pkgs.light}/bin/light -A 2";
            on-scroll-down = "${pkgs.light}/bin/light -U 1";
          };
          pulseaudio = {
            format = "{icon}&#8239;{volume}% {format_source}";
            format-bluetooth = "{volume}% {icon}  {format_source}";
            format-bluetooth-muted = "{volume}% 󰟎 {format_source}";
            format-muted = " {volume}% {format_source}";
            format-source-muted = "";
            format-icons = {
              "default" = [ "" "" "" ];
              headphone = "󰋋";
              hands-free = "";
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
            format-wifi = " {essid} ({signalStrength}%)";
            format-ethernet = " {ipaddr}/{cidr}";
            tooltip-format = " {ifname} via {gwaddr}";
            format-linked = " {ifname} (No IP)";
            format-disconnected = "⚠ Disconnected";
            format-alt = "{ifname}: {ipaddr}/{cidr}";
            tooltip = true;
          };
          idle_inhibitor = {
            format = "{icon}";
            format-icons = {
              activated = "";
              deactivated = "";
            };
          };
          tray = { spacing = 10; };

          "custom/separator" = {
            format = "|";
            interval = "once";
            tooltip = false;
          };

          "hyprland/workspaces" = {
            sort-by-name = true;
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

          "custom/media" = {
            format = "{icon}{}";
            return-type = "json";
            format-icons = {
              Playing = " ";
              Paused = " ";
            };
            max-length = 30;
            exec = ''
              ${pkgs.playerctl}/bin/playerctl -a metadata --format '{"text": "{{playerName}}: {{artist}} - {{markup_escape(title)}}", "tooltip": "{{playerName}} : {{markup_escape(title)}}", "alt": "{{status}}", "class": "{{status}}"}' -F'';
            on-click = "${pkgs.playerctl}/bin/playerctl play-pause";
            smooth-scrolling-threshold = 5;
            on-scroll-up = "${pkgs.playerctl}/bin/playerctl next";
            on-scroll-down = "${pkgs.playerctl}/bin/playerctl previous";
          };
          #};
        };
      };
      style = ./waybar-style.css;
      systemd.enable = true;
    };
  };
}
