{
  config,
  pkgs,
  lib,
  ...
}:
with lib;
let
  cfg = config.nixconf.services.display-manager.hyprland;
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

  switch-input-method = pkgs.writeShellScriptBin "switch-input-method" ''
    if [ $(ibus engine) == xkb:us::eng ]; then ibus engine Bamboo; else ibus engine xkb:us::eng ; fi
  '';
  screenshot-region = pkgs.writeShellScriptBin "screenshot-region" ''
    ${pkgs.grim}/bin/grim -g "$(${pkgs.slurp}/bin/slurp)" - | ${pkgs.wl-clipboard}/bin/wl-copy
  '';
  toggle-special = pkgs.writeShellScriptBin "toggle-special" ''
    count=$(hyprctl clients -j | ${pkgs.jq}/bin/jq '[.[] | select(.workspace.name == "special:term")] | length')
    if [ "$count" -eq 0 ]; then
      hyprctl dispatch exec "[workspace special:term]" ${lib.getExe pkgs.alacritty}
    else
      hyprctl dispatch togglespecialworkspace term
    fi
  '';

  suspend-countdown = pkgs.writeShellScriptBin "suspend-countdown" ''
    SUSPEND_TIMEOUT=${toString cfg.suspendTimeout}
    LAST_ACTIVE=$(date +%s)
    LAST_CURSOR=""

    while true; do
      now=$(date +%s)

      # Detect activity by checking cursor position changes
      cursor=$(hyprctl cursorpos 2>/dev/null)
      if [ "$cursor" != "$LAST_CURSOR" ]; then
        LAST_ACTIVE=$now
        LAST_CURSOR="$cursor"
      fi

      idle_sec=$((now - LAST_ACTIVE))
      remaining=$((SUSPEND_TIMEOUT - idle_sec))
      if [ "$remaining" -le 0 ]; then
        remaining=0
      fi

      if [ "$remaining" -le 60 ]; then
        # Last minute: show seconds
        class="warning"
        printf '{"text": "󰒲 %ds", "tooltip": "Suspend in %d seconds", "class": "%s"}\n' "$remaining" "$remaining" "$class"
      else
        # Round up to minutes
        mins=$(( (remaining + 59) / 60 ))
        if [ "$remaining" -le 300 ]; then
          class="warning"
        else
          class="normal"
        fi
        printf '{"text": "󰒲 %dm", "tooltip": "Suspend in %d minutes", "class": "%s"}\n' "$mins" "$mins" "$class"
      fi
      sleep 30
    done
  '';

  toggle-layout = pkgs.writeShellScriptBin "toggle-layout" ''
    STATE_FILE="/tmp/hypr-layout-mode"

    # Find any external monitor (non-eDP)
    ext_monitor=$(hyprctl monitors -j | ${pkgs.jq}/bin/jq -r '.[] | select(.name | startswith("eDP") | not) | .name' | head -1)

    if [ -z "$ext_monitor" ]; then
      exit 0
    fi

    # Detect current layout from actual monitor position instead of state file
    # Side layout: external x = -3440; Above layout: external x = -920
    ext_x=$(hyprctl monitors -j | ${pkgs.jq}/bin/jq -r ".[] | select(.name == \"$ext_monitor\") | .x")
    if [ "$ext_x" -lt -2000 ] 2>/dev/null; then
      current="side"
    else
      current="above"
    fi

    if [ "$current" = "side" ]; then
      # Switch to above layout
      # eDP-1 logical @1.33: 1600x1000, centered: -920 = (1600 - 3440) / 2
      hyprctl keyword monitor "eDP-1,2560x1600@120,0x0,1.33,vrr,1"
      hyprctl keyword monitor "$ext_monitor,3440x1440@120,-920x-1440,1,bitdepth,10,vrr,1"
      echo "above" > "$STATE_FILE"
    else
      # Switch to side layout (laptop right, bottom-aligned)
      # eDP-1 logical @1.33: 1600x1000, bottom-aligned: -440 = 1000 - 1440
      hyprctl keyword monitor "eDP-1,2560x1600@120,0x0,1.33,vrr,1"
      hyprctl keyword monitor "$ext_monitor,3440x1440@120,-3440x-440,1,bitdepth,10,vrr,1"
      echo "side" > "$STATE_FILE"
    fi

    # Restart waybar to pick up new monitor layout
    systemctl --user restart waybar
  '';

  monitor-scale = pkgs.writeShellScriptBin "monitor-scale" ''
    apply_config() {
      # Find any external monitor (non-eDP)
      ext_monitor=$(hyprctl monitors -j | ${pkgs.jq}/bin/jq -r '.[] | select(.name | startswith("eDP") | not) | .name' | head -1)

      if [ -n "$ext_monitor" ]; then
        # External monitor connected - use scale 1.33 for laptop
        hyprctl keyword monitor "eDP-1,2560x1600@120,0x0,1.33,vrr,1"

        # Apply layout based on saved preference (default: side)
        layout=$(cat /tmp/hypr-layout-mode 2>/dev/null || echo "side")
        if [ "$layout" = "above" ]; then
          # External above laptop, centered: -920 = (1600 - 3440) / 2
          hyprctl keyword monitor "$ext_monitor,3440x1440@120,-920x-1440,1,bitdepth,10,vrr,1"
        else
          layout="side"
          # Laptop right of external, bottom-aligned: -440 = 1000 - 1440
          hyprctl keyword monitor "$ext_monitor,3440x1440@120,-3440x-440,1,bitdepth,10,vrr,1"
        fi
        # Keep state file in sync with actual layout
        echo "$layout" > /tmp/hypr-layout-mode
      else
        # Single monitor, scale 1.0
        hyprctl keyword monitor "eDP-1,2560x1600@120,0x0,1,vrr,1"
      fi
    }

    # Apply on startup (brief delay to let Hyprland initialize monitors)
    sleep 0.5
    apply_config

    # Listen for monitor hotplug events
    ${pkgs.socat}/bin/socat -U - UNIX-CONNECT:"$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" | while read -r line; do
      case "$line" in
        monitoradded*|monitorremoved*)
          sleep 0.5
          apply_config
          # Restart waybar to pick up new monitor layout
          systemctl --user restart waybar
          ;;
      esac
    done
  '';

  cycle-hypr-layout = pkgs.writeShellScriptBin "cycle-hypr-layout" ''
    DEFAULT_LAYOUT="${cfg.defaultLayout}"
    if [ "$1" == "--reset" ]; then
      hyprctl keyword general:layout "$DEFAULT_LAYOUT"
      ${pkgs.dunst}/bin/dunstify -r 9993 -a "Hyprland" "Layout Reset" "Switched to $DEFAULT_LAYOUT"
      exit 0
    fi

    CURRENT=$(hyprctl getoption general:layout -j | ${pkgs.jq}/bin/jq -r '.str')
    if [ "$CURRENT" == "master" ]; then
      NEXT="dwindle"
    elif [ "$CURRENT" == "dwindle" ]; then
      NEXT="scrolling"
    else
      NEXT="master"
    fi

    hyprctl keyword general:layout "$NEXT"
    ${pkgs.dunst}/bin/dunstify -r 9993 -a "Hyprland" "Layout Change" "Switched to $NEXT"
  '';

in
{
  options.nixconf.services.display-manager.hyprland = {
    enable = mkEnableOption "Enable Hyprland display server";

    defaultLayout = mkOption {
      type = types.enum [ "master" "dwindle" "scrolling" ];
      default = "master";
      description = "Default layout to use for Hyprland";
    };

    window = mkOption {
      type = types.enum [
        "default"
        "no-border"
        "no-border-more-gaps"
        "no-border-no-gaps"
        "border-1"
        "border-2"
        "border-3"
        "border-4"
        "border-1-reverse"
        "border-2-reverse"
        "border-3-reverse"
        "border-4-reverse"
      ];

      default = "default";
    };

    decoration = mkOption {
      type = types.enum [
        "default"
        "rounding"
        "rounding-more-blur"
        "rounding-all-blur"
        "rounding-all-blur-no-shadows"
        "no-rounding"
        "no-rounding-more-blur"
      ];
      default = "default";
    };

    animation = mkOption {
      type = types.enum [
        "default"
        "moving"
        "fast"
        "high"
      ];
      default = "default";
    };

    dpmsTimeout = mkOption {
      type = types.int;
      default = 1500;
      description = "Idle seconds before turning off displays (DPMS)";
    };

    suspendTimeout = mkOption {
      type = types.int;
      default = 1800;
      description = "Idle seconds before suspending the system";
    };

  };

  imports = [
    ./waybar
    ./hyprpanel
  ];

  config = mkIf cfg.enable (mkMerge [
    {
      nixconf = {
        apps.rofi.enable = true;
        apps.wal.enable = true;
        services.display-manager.hyprland = {
          waybar.enable = true;
        };
      };

      home.sessionVariables = {
        QT_QPA_PLATFORM = "wayland";
      };

      home.packages = with pkgs; [
        switch-input-method
        screenshot-region
        toggle-special
        cycle-hypr-layout
        toggle-layout
        monitor-scale
        suspend-countdown
        wl-clipboard
        cliphist
        pamixer
        dunst
        qt5.qtwayland
        qt6.qtwayland
        nautilus
        btop
        wlr-randr
        hypridle
        pavucontrol
        wtype
      ];

      fonts.fontconfig.enable = true;
      # Using cliphist + wl-clipboard instead of copyq (native Wayland support)

      services.hyprpaper = {
        enable = true;
        settings = {
          wallpaper =
            let
              pic = "countryside_landscape.jpg";
            in
            [
              {
                monitor = "DP-1";
                path = "${./wallpapers}/${pic}";
              }
              {
                monitor = "DP-2";
                path = "${./wallpapers}/${pic}";
              }
              {
                monitor = "eDP-1";
                path = "${./wallpapers}/${pic}";
              }

            ];
        };
      };

      xdg.configFile = {
        "dunst" = {
          source = ./dunst;
          recursive = true;
        };

        # If you’re using the NixOS module with UWSM (programs.hyprland.withUWSM = true), you can set environment variables like this:
        "uwsm/env".source = "${config.home.sessionVariablesPackage}/etc/profile.d/hm-session-vars.sh";

        "hypr/hypridle.conf".text = ''
          general {
              after_sleep_cmd = hyprctl dispatch dpms on
              ignore_dbus_inhibit = false
          }

          listener {
              timeout = ${toString cfg.dpmsTimeout}
              on-timeout = hyprctl dispatch dpms off
              on-resume = hyprctl dispatch dpms on
          }

          listener {
              timeout = ${toString cfg.suspendTimeout}
              on-timeout = systemctl suspend
          }
        '';
      };

      i18n.inputMethod = {
        type = "fcitx5";
        fcitx5 = {
          waylandFrontend = true;
          addons = [
            pkgs.fcitx5-gtk
            pkgs.fcitx5-bamboo
          ];
        };
      };

      systemd.user.services = {
        dunst = {
          Unit = {
            Description = "Dunst notification daemon";
            After = [ "hm-graphical-session.target" ];
            PartOf = [ "graphical-session.target" ];
          };

          Service = {
            Type = "dbus";
            BusName = "org.freedesktop.Notifications";
            ExecStart = "${pkgs.dunst}/bin/dunst";
          };
          Install = {
            WantedBy = [ "graphical-session.target" ];
          };
        };
      };
    }

    {
      home.sessionVariables = {
        XDG_SESSION_DESKTOP = "Hyprland";
        XDG_CURRENT_DESKTOP = "Hyprland";
        # GTK_IM_MODULE = "fcitx";
        # QT_IM_MODULE = "fcitx";
        # XMODIFIERS = "@im=fcitx";
        # SDL_IM_MODULE = "fcitx";
        # GLFW_IM_MODULE = "fcitx";
        # QT_IM_MODULES = "wayland;fcitx;ibus";
      };

      gtk.gtk3.extraConfig = {
        gtk-im-module = "fcitx";
      };

      gtk.gtk4.extraConfig = {
        gtk-im-module = "fcitx";
      };

      wayland.windowManager.hyprland = {
        enable = true;
        configType = "lua";

        # set the Hyprland and XDPH packages to null to use the ones from the NixOS module
        package = null;
        portalPackage = null;
        systemd = {
          enable = true;
          variables = [ "--all" ];
          enableXdgAutostart = true;
        };
        xwayland.enable = true;
        # systemd.extraCommands = [ "ibus-deamon -d" ];

        settings = lib.mkMerge [
          {
            exec_once = [
              "fcitx5 -r"
              "${pkgs.dunst}/bin/dunst"
              "monitor-scale"
              "${pkgs.wl-clipboard}/bin/wl-paste --watch ${pkgs.cliphist}/bin/cliphist store"
              "hypridle"
            ];

            general = {
              snap.enabled = true;
              layout = cfg.defaultLayout;
            };
            monitor = [
              "eDP-1,2560x1600@120,0x0,1.33,vrr,1"
              "DP-1, 3440x1440@120,-3440x-440,1,bitdepth,10,vrr,1"
              "DP-2, 3440x1440@120,-3440x-440,1,bitdepth,10,vrr,1"
              ",preferred,auto,1"
            ];

            input = {
              kb_layout = "us";
              kb_options = "caps:escape";
              follow_mouse = 1;
              mouse_refocus = false;
              sensitivity = 0.6;
              touchpad = {
                natural_scroll = false;
                disable_while_typing = true;
                tap_button_map = "lrm";
                clickfinger_behavior = true;
                tap-to-click = true;
              };
            };

            dwindle = {
              preserve_split = true;
              special_scale_factor = 0.85;
            };

            master = {
              new_status = "master";
              new_on_top = false;
              new_on_active = "after";
              special_scale_factor = 0.85;
              orientation = "right";
            };

            mod = { _var = "SUPER"; };

            workspace = [
              "w[t1], gapsin:0, gapsout:0, border:false"
            ];

            windowrule = [
              "match:class ^(org.pulseaudio.pavucontrol), float on, size 800 800"
              "match:class ^(.blueman-manager-wrapped), float on, size 800 600"
              "match:class ^(nm-connection-editor)$, float on"
              "match:class (Rofi), stay_focused on"
              "match:class ^(firefox|google-chrome|microsoft-edge), opacity 1 1"
            ];
            layerrule = [
              "blur on, match:namespace gtk-layer-shell"
              "blur on, match:namespace logout_dialog"
            ];

            bind = [
              "SUPER, grave, exec, cycle-hypr-layout"
              "SUPER SHIFT, grave, exec, cycle-hypr-layout --reset"
              "SUPER SHIFT, RETURN, exec, alacritty"
              "SUPER SHIFT, C, killactive,"
              "SUPER, Q, exec, systemctl suspend"
              "SUPER SHIFT, Q, exec, systemctl suspend"
              "SUPER, m, layoutmsg, focusmaster"
              "SUPER, RETURN, layoutmsg, swapwithmaster"

              # 1D Stack Navigation (J/K)
              "SUPER, J, cyclenext"
              "SUPER, K, cyclenext, prev"

              # 1D Window Moving (J/K)
              "SUPER SHIFT, J, swapnext"
              "SUPER SHIFT, K, swapnext, prev"

              "SUPER, T, togglefloating,"
              "SUPER, P, exec, rofi -show drun -replace -i -show-icons"
              "SUPER, backslash, exec, screenshot-region"
              "SUPER, V, exec, ${pkgs.cliphist}/bin/cliphist list | rofi -dmenu -p clipboard -i | ${pkgs.cliphist}/bin/cliphist decode | ${pkgs.wl-clipboard}/bin/wl-copy && sleep 0.1 && ${pkgs.wtype}/bin/wtype -M shift -k insert -m shift"
              "SUPER SHIFT, M, exec, toggle-layout"
              "SUPER, F, fullscreen,1"
              "SUPER SHIFT, F, fullscreen,0"

              #apps
              "SUPER, B, exec, firefox"
              "SUPER, D, exec, nautilus"

              # media keys
              ",121,exec, pamixer --toggle-mute"
              ",122,exec, pamixer -d 5"
              ",123,exec, pamixer -i 5"

              "SUPER,slash, exec, fcitx5-remote -s keyboard-us"
              "SUPER SHIFT, slash, exec, fcitx5-remote -s bamboo"

              "SUPER,W, focusmonitor, DP-2"
              "SUPER,W, focusmonitor, DP-1"
              "SUPER,E, focusmonitor,eDP-1"

              # 2D Spatial Navigation with mod + arrow keys
              "SUPER, left, movefocus, l"
              "SUPER, right, movefocus, r"
              "SUPER, up, movefocus, u"
              "SUPER, down, movefocus, d"
              "SUPER SHIFT, left, resizeactive, -40 0"
              "SUPER SHIFT, right, resizeactive, 40 0"
              "SUPER SHIFT, up, resizeactive, 0 -40"
              "SUPER SHIFT, down, resizeactive, 0 40"

              # Switch workspaces with mod + [0-9]
              "SUPER,1,moveworkspacetomonitor,1 current"
              "SUPER, 1, workspace, 1"
              "SUPER,2,moveworkspacetomonitor,2 current"
              "SUPER, 2, workspace, 2"
              "SUPER,3,moveworkspacetomonitor,3 current"
              "SUPER, 3, workspace, 3"
              "SUPER,4,moveworkspacetomonitor,4 current"
              "SUPER, 4, workspace, 4"
              "SUPER,5,moveworkspacetomonitor,5 current"
              "SUPER, 5, workspace, 5"
              "SUPER,6,moveworkspacetomonitor,6 current"
              "SUPER, 6, workspace, 6"
              "SUPER,7,moveworkspacetomonitor,7 current"
              "SUPER, 7, workspace, 7"
              "SUPER,8,moveworkspacetomonitor,8 current"
              "SUPER, 8, workspace, 8"
              "SUPER,9,moveworkspacetomonitor,9 current"
              "SUPER, 9, workspace, 9"
              "SUPER,0,moveworkspacetomonitor,10 current"
              "SUPER, 0, workspace, 10"
              "SUPER, space, exec, toggle-special"

              # Move active window to a workspace with mod + SHIFT + [0-9]
              "SUPER SHIFT, 1, movetoworkspacesilent, 1"
              "SUPER SHIFT, 2, movetoworkspacesilent, 2"
              "SUPER SHIFT, 3, movetoworkspacesilent, 3"
              "SUPER SHIFT, 4, movetoworkspacesilent, 4"
              "SUPER SHIFT, 5, movetoworkspacesilent, 5"
              "SUPER SHIFT, 6, movetoworkspacesilent, 6"
              "SUPER SHIFT, 7, movetoworkspacesilent, 7"
              "SUPER SHIFT, 8, movetoworkspacesilent, 8"
              "SUPER SHIFT, 9, movetoworkspacesilent, 9"
              "SUPER SHIFT, 0, movetoworkspacesilent, 10"
              "SUPER SHIFT, space, movetoworkspacesilent, special:term"

              "SUPER, mouse_down, workspace, e+1"
              "SUPER, mouse_up, workspace, e-1"
            ];
            bindm = [
              "SUPER, mouse:272, movewindow"
              "SUPER, mouse:273, resizewindow"
            ];

            misc = {
              disable_hyprland_logo = true;
              disable_splash_rendering = true;
              key_press_enables_dpms = true;
              on_focus_under_fullscreen = 1;
              focus_on_activate = true;
            };

            env = [
              "GDK_BACKEND,wayland,x11"
              "QT_QPA_PLATFORM,wayland;xcb"
              "CLUTTER_BACKEND,wayland"
              "QT_AUTO_SCREEN_SCALE_FACTOR,1"
              "QT_WAYLAND_DISABLE_WINDOWDECORATION,1"
            ];

            debug = {
              vfr = true;
            };
          }
          {
            animations = import ./animations/${cfg.animation}.nix;
            decoration = import ./decorations/${cfg.decoration}.nix;
            general = import ./windows/${cfg.window}.nix;
          }
        ];
      };
    }

    {
      wayland.windowManager.hyprland.extraConfig = ''
        pcall(dofile, (os.getenv("HOME") or "/home/thongpv87") .. "/.cache/wal/colors-hyprland.lua")
      '';
    }
  ]);
}
