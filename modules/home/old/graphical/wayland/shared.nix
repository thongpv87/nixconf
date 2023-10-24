{ pkgs, config, lib, ... }:
with lib;
let
  cfg = config.nixconf.old.graphical.wayland;
  systemCfg = config.machineData.systemConfig;
  isLaptop = systemCfg ? framework && systemCfg.framework.enable;

  screenNames = if isLaptop then [ "eDP-1" ] else [ "HDMI-A-1" "DP-1" ];

  # wlr-randr --on does not work for some reason on dwl. not using currently
  poweroffScreen = pkgs.writeShellApplication {
    name = "poweroff-screen";
    runtimeInputs = with pkgs; [ wlr-randr ];
    text = builtins.concatStringsSep "\n"
      (builtins.map screenNames (v: "wlr-randr --output ${v} --off"));
  };

  poweronScreen = pkgs.writeShellApplication {
    name = "poweron-screen";
    runtimeInputs = with pkgs; [ wlr-randr ];
    text = builtins.concatStringsSep "\n"
      (builtins.map screenNames (v: "wlr-randr --output ${v} --on"));
  };
in {
  options.nixconf.old.graphical.wayland = {
    enable = mkOption {
      type = types.bool;
      description = "Enable wayland";
    };

    background = {
      enable = mkOption {
        type = types.bool;
        description = "Enable background [wpaperd]";
      };

      path = mkOption {
        type = types.str;
        default = "~/Pictures/Wallpapers";
        description = "Path to image file used for background";
      };
    };

    screenlock = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description =
          "Enable screen locking, must enable it on system as well for pam.d (waylock)";
      };

      type = mkOption {
        type = types.enum [ "waylock" "swaylock" ];
        description = "Which screen locking software to use";
      };

      timeout = mkOption {
        type = types.int;
        default = 180;
        description = "Timeout for locking the screen";
      };
    };

    statusbar = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable status bar [waybar]";
      };

      pkg = mkOption {
        type = types.package;
        default = pkgs.waybar-hyprland;
        description = "Waybar package";
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      home.packages = with pkgs; [
        wl-clipboard
        wlr-randr
        wdisplays
        libappindicator-gtk3
        dunst
      ];

      systemd.user.targets.wayland-session = {
        Unit = {
          Description = "wayland graphical session";
          BindsTo = [ "graphical-session.target" ];
          Wants = [ "graphical-session-pre.target" ];
          After = [ "graphical-session-pre.target" ];
        };
      };
    }
    (mkIf cfg.screenlock.enable (let
      isWaylock = cfg.screenlock.type == "waylock";
      isSwaylock = cfg.screenlock.type == "swaylock";
    in {
      assertions = [{
        assertion = isWaylock
          -> (systemCfg.graphical.wayland.waylockPam && isWaylock);
        message =
          "Waylock PAM must be enabled by the system to use waylock screen locking.";
      }

      # {
      #   assertion = isSwaylock
      #     -> (systemCfg.graphical.wayland.swaylockPam && isSwaylock);
      #   message =
      #     "Swaylock PAM must be enabled by the system to use waylock screen locking.";
      # }
        ];

      services.swayidle = let
        lockCommand = if cfg.screenlock.type == "waylock" then
          "${pkgs.waylock}/bin/waylock -fork-on-lock"
        else
          "${pkgs.swaylock}/bin/swaylock -f";
      in {
        enable = true;
        timeouts = [{
          timeout = cfg.screenlock.timeout;
          command = lockCommand;
        }];
        # Soemtimes wlr-randr fails to turn screen back on, comment out for now
        # ++ optional isLaptop {
        #   timeout = 60;
        #   command = "${pkgs.wlr-randr}/bin/wlr-randr --output eDP-1 --off";
        #   resumeCommand = "${pkgs.wlr-randr}/bin/wlr-randr --output eDP-1 --on";
        # };

        events = [{
          event = "before-sleep";
          command = lockCommand;
        }];
        systemdTarget = "hyprland-session.target";
        extraArgs = [ "idlehint 600" ];
      };

      home.packages = with pkgs;
        (optional (cfg.screenlock.type == "waylock") waylock)
        ++ (optional (cfg.screenlock.type == "swaylock") swaylock);
    }))
    (mkIf cfg.background.enable {
      home.packages = [ pkgs.wpaperd ];

      xdg.configFile."wpaperd/wallpaper.toml".text = ''
        [default]
        path = "${cfg.background.path}"
        duration = "30m"
        sorting = "ascending"
      '';
      systemd.user.services.wpaperd = mkIf cfg.background.enable {
        Unit = {
          Description = "wpaperd background service";
          Documentation = [ "man:wpaperd(1)" ];
          Requires = [ "hyprland-session.target" ];
          After = [ "hyprland-session.target" ];
          Before = mkIf (cfg.statusbar.enable) [ "waybar.service" ];
        };

        Service = { ExecStart = "${pkgs.wpaperd}/bin/wpaperd"; };

        Install = { WantedBy = [ "hyprland-session.target" ]; };
      };
    })
    (mkIf (cfg.statusbar.enable) {
      programs.waybar = {
        enable = true;
        package = cfg.statusbar.pkg;
        settings = {
          mainbar = {
            layer = "top";
            # output = [ primaryDisplay ];

            modules-left = [ "wlr/workspaces" ];
            modules-center = [ "custom/media" ];
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
              format = "{icon}&#8239;{capacity}%";
              format-charging = "󰂄&#8239;{capacity}%";
              format-plugged = "&#8239;{capacity}%";
              format-alt = "{icon} {time}";
              format-icons = [ "" "" "" "" "" ];
              tooltip = false;
              tooltip-format = "{timeTo}";
            };
            backlight = {
              device = "acpi_video1";
              format = "{icon}&#8239;{percent}%";
              format-icons = [ "" "" ];
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

            "wlr/workspaces" = {
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
              smooth-scrolling-threshold = if isLaptop then 10 else 5;
              on-scroll-up = "${pkgs.playerctl}/bin/playerctl next";
              on-scroll-down = "${pkgs.playerctl}/bin/playerctl previous";
            };
            #};
          };
        };
        style = readFile ./waybar-style.css;
        systemd.enable = false;
      };

      systemd.user.services.waybar = {
        Unit = {
          Description =
            "Highly customizable Wayland bar for Sway and Wlroots based compositors.";
          Documentation = "https://github.com/Alexays/Waybar/wiki";
          BindsTo = [ "hyprland-session.target" ];
          After = [ "hyprland-session.target" ];
          Wants = [ "tray.target" ];
          Before = [ "tray.target" ];
        };

        Service = {
          ExecStart = "${pkgs.waybar-hyprland}/bin/waybar";
          ExecReload = "${pkgs.coreutils}/bin/kill -SIGUSR2 $MAINPID";
          Restart = "on-failure";
          KillMode = "mixed";
        };

        Install = { WantedBy = [ "hyprland-session.target" ]; };
      };
    })
  ]);
}
