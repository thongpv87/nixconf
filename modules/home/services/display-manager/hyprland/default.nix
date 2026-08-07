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

    useIlyamiroConfig = mkOption {
      type = types.bool;
      default = false;
      description = "Enable experimental ilyamiro shell profile (quickshell, matugen, rofi, cava)";
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
        services.display-manager.hyprland = {
          waybar.enable = mkDefault (!cfg.useIlyamiroConfig);
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

      services.hyprpaper = mkIf (!cfg.useIlyamiroConfig) {
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
        configType = "hyprlang";
        sourceFirst = true;

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
            exec-once = [
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

            "$mod" = "SUPER";

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
              "$mod, grave, exec, cycle-hypr-layout"
              "$mod SHIFT, grave, exec, cycle-hypr-layout --reset"
              "$mod SHIFT, RETURN, exec, alacritty"
              "$mod SHIFT, C, killactive,"
              "$mod, Q, exec, systemctl suspend"
              "$mod SHIFT, Q, exec, systemctl suspend"
              "$mod, m, layoutmsg, focusmaster"
              "$mod, RETURN, layoutmsg, swapwithmaster"

              # 1D Stack Navigation (J/K)
              "$mod, J, cyclenext"
              "$mod, K, cyclenext, prev"

              # 1D Window Moving (J/K)
              "$mod SHIFT, J, swapnext"
              "$mod SHIFT, K, swapnext, prev"

              "$mod, T, togglefloating,"
              "$mod, P, exec, rofi -show drun -replace -i -show-icons"
              "$mod, backslash, exec, screenshot-region"
              "$mod, V, exec, ${pkgs.cliphist}/bin/cliphist list | rofi -dmenu -p clipboard -i | ${pkgs.cliphist}/bin/cliphist decode | ${pkgs.wl-clipboard}/bin/wl-copy && sleep 0.1 && ${pkgs.wtype}/bin/wtype -M shift -k insert -m shift"
              "$mod SHIFT, M, exec, toggle-layout"
              "$mod, F, fullscreen,1"
              "$mod SHIFT, F, fullscreen,0"

              #apps
              "$mod, B, exec, firefox"
              "$mod, D, exec, nautilus"

              # media keys
              ",121,exec, pamixer --toggle-mute"
              ",122,exec, pamixer -d 5"
              ",123,exec, pamixer -i 5"

              "$mod,slash, exec, fcitx5-remote -s keyboard-us"
              "$mod SHIFT, slash, exec, fcitx5-remote -s bamboo"

              "$mod,W, focusmonitor, DP-2"
              "$mod,W, focusmonitor, DP-1"
              "$mod,E, focusmonitor,eDP-1"

              # 2D Spatial Navigation with mod + arrow keys
              "$mod, left, movefocus, l"
              "$mod, right, movefocus, r"
              "$mod, up, movefocus, u"
              "$mod, down, movefocus, d"
              "$mod SHIFT, left, resizeactive, -40 0"
              "$mod SHIFT, right, resizeactive, 40 0"
              "$mod SHIFT, up, resizeactive, 0 -40"
              "$mod SHIFT, down, resizeactive, 0 40"

              # Switch workspaces with mod + [0-9]
              "$mod,1,moveworkspacetomonitor,1 current"
              "$mod, 1, workspace, 1"
              "$mod,2,moveworkspacetomonitor,2 current"
              "$mod, 2, workspace, 2"
              "$mod,3,moveworkspacetomonitor,3 current"
              "$mod, 3, workspace, 3"
              "$mod,4,moveworkspacetomonitor,4 current"
              "$mod, 4, workspace, 4"
              "$mod,5,moveworkspacetomonitor,5 current"
              "$mod, 5, workspace, 5"
              "$mod,6,moveworkspacetomonitor,6 current"
              "$mod, 6, workspace, 6"
              "$mod,7,moveworkspacetomonitor,7 current"
              "$mod, 7, workspace, 7"
              "$mod,8,moveworkspacetomonitor,8 current"
              "$mod, 8, workspace, 8"
              "$mod,9,moveworkspacetomonitor,9 current"
              "$mod, 9, workspace, 9"
              "$mod,0,moveworkspacetomonitor,10 current"
              "$mod, 0, workspace, 10"
              "$mod, space, exec, toggle-special"

              # Move active window to a workspace with mod + SHIFT + [0-9]
              "$mod SHIFT, 1, movetoworkspacesilent, 1"
              "$mod SHIFT, 2, movetoworkspacesilent, 2"
              "$mod SHIFT, 3, movetoworkspacesilent, 3"
              "$mod SHIFT, 4, movetoworkspacesilent, 4"
              "$mod SHIFT, 5, movetoworkspacesilent, 5"
              "$mod SHIFT, 6, movetoworkspacesilent, 6"
              "$mod SHIFT, 7, movetoworkspacesilent, 7"
              "$mod SHIFT, 8, movetoworkspacesilent, 8"
              "$mod SHIFT, 9, movetoworkspacesilent, 9"
              "$mod SHIFT, 0, movetoworkspacesilent, 10"
              "$mod SHIFT, space, movetoworkspacesilent, special:term"

              "$mod, mouse_down, workspace, e+1"
              "$mod, mouse_up, workspace, e-1"
            ];
            bindm = [
              "$mod, mouse:272, movewindow"
              "$mod, mouse:273, resizewindow"
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
          (lib.mkIf (!cfg.useIlyamiroConfig) {
            source = [ "/home/thongpv87/.cache/wal/colors-hyprland.conf" ];
            animations = import ./animations/${cfg.animation}.nix;
            decoration = import ./decorations/${cfg.decoration}.nix;
            general = import ./windows/${cfg.window}.nix;
          })
        ];
      };
    }

    (mkIf cfg.useIlyamiroConfig {
      nixconf.apps.wal.enable = mkForce false;

      home.packages = with pkgs; [
        quickshell
        matugen
        swww
        swayosd
        cava
        playerctl
        socat
        bc
        jq
        acpi
        iw
        bluez
        libnotify
        lm_sensors
        imagemagick
        ffmpeg
        python3
        pulseaudio # for pactl subscribe in volume_listener.sh
      ];

      services.swayosd = {
        enable = true;
        topMargin = 0.9;
      };

      xdg.configFile = {
        "hypr/scripts".source = ./../../../../../.ilyamiro_upstream/config/sessions/hyprland/scripts;
        "hypr/templates".source = ./../../../../../.ilyamiro_upstream/config/sessions/hyprland/templates;
        "matugen".source = ./../../../../../.ilyamiro_upstream/config/programs/matugen;
        "cava/config_base".source = ./../../../../../.ilyamiro_upstream/config/programs/cava/config;

        # Default colors.conf so hyprland doesn't crash before matugen runs
        "hypr/colors.conf".text = ''
          $active_border = rgba(7aa2f7ee)
          $inactive_border = rgba(565f89aa)
        '';

        # Default settings.json for quickshell
        "hypr/settings.json".text = builtins.toJSON {
          uiScale = 1.0;
          openGuideAtStartup = true;
          topbarHelpIcon = true;
          workspaceCount = 10;
          wallpaperDir = "${config.home.homeDirectory}/Pictures/Wallpapers";
          language = "us";
          kbOptions = "caps:escape";
        };
      };

      wayland.windowManager.hyprland.settings = lib.mkMerge [
        {
          # Override exec-once to use ilyamiro's autostart
          exec-once = mkForce [
            "fcitx5 -r"
            "${pkgs.dunst}/bin/dunst"
            "monitor-scale"
            "${pkgs.wl-clipboard}/bin/wl-paste --type text --watch ${pkgs.cliphist}/bin/cliphist store"
            "${pkgs.wl-clipboard}/bin/wl-paste --type image --watch ${pkgs.cliphist}/bin/cliphist store"
            "swww-daemon"
            "hypridle"
            "playerctld"
            "~/.config/hypr/scripts/volume_listener.sh"
            "quickshell -p ~/.config/hypr/scripts/quickshell/Shell.qml"
          ];

          # ilyamiro-style general (uses matugen color vars)
          general = mkForce {
            border_size = 2;
            gaps_in = 4;
            gaps_out = 4;
            resize_on_border = true;
            extend_border_grab_area = 30;
            snap.enabled = true;
            layout = cfg.defaultLayout;
            "col.active_border" = "$active_border";
            "col.inactive_border" = "$inactive_border";
          };

          # ilyamiro-style decoration
          decoration = mkForce {
            rounding = 4;
            active_opacity = 1.0;
            inactive_opacity = 1.0;
            blur = {
              enabled = true;
              size = 8;
              passes = 2;
              new_optimizations = true;
            };
            shadow = {
              enabled = false;
            };
          };

          # ilyamiro-style animations
          animations = mkForce {
            enabled = true;
            bezier = [
              "myBezier, 0.05, 0.9, 0.1, 1.05"
            ];
            animation = [
              "windows, 1, 5, myBezier, popin 80%"
              "windowsOut, 1, 5, myBezier, popin 80%"
              "layers, 1, 5, myBezier, fade"
              "layersIn, 1, 5, myBezier, fade"
              "layersOut, 1, 5, myBezier, fade"
              "fade, 1, 5, myBezier"
              "workspaces, 1, 5, myBezier, slide"
              "specialWorkspaceIn, 1, 5, myBezier, fade"
              "specialWorkspaceOut, 1, 5, myBezier, fade"
            ];
          };

          misc = mkForce {
            disable_hyprland_logo = true;
            disable_splash_rendering = true;
            focus_on_activate = true;
            key_press_enables_dpms = true;
            font_family = "JetBrains Mono";
          };

          # Quickshell passthru submap (required for quickshell to intercept keys)
          "$mainMod" = "SUPER";
        }

        # ilyamiro-specific keybindings and rules
        {
          # ilyamiro layer rules for quickshell/OSD
          layerrule = mkForce [
            "noanim, match:namespace volume_osd"
            "noanim, match:namespace brightness_osd"
            "noanim, match:namespace hyprpicker"
            "noanim, match:namespace qsdock"
            "blur on, match:namespace ext-session-lock"
            "ignorealpha 0.2, match:namespace ext-session-lock"
          ];

          windowrule = mkForce [
            "match:class ^(org.pulseaudio.pavucontrol), float on, size 800 800"
            "match:class ^(.blueman-manager-wrapped), float on, size 800 600"
            "match:class ^(nm-connection-editor)$, float on"
            "match:class ^(firefox|google-chrome|microsoft-edge), opacity 1 1"
            "match:title ^(app-launcher)$, float on, center on, size 1200 600"
          ];

          # Merge keybinds: keep user essentials + add quickshell IPC binds
          bind = mkForce [
            # ─── User essentials (kept from your config) ───
            "$mainMod, grave, exec, cycle-hypr-layout"
            "$mainMod SHIFT, grave, exec, cycle-hypr-layout --reset"
            "$mainMod SHIFT, RETURN, exec, alacritty"
            "ALT, F4, exec, hyprctl dispatch killactive"
            "$mainMod, m, layoutmsg, focusmaster"
            "$mainMod, RETURN, layoutmsg, swapwithmaster"
            "$mainMod, J, cyclenext"
            "$mainMod, K, cyclenext, prev"
            "$mainMod SHIFT, J, swapnext"
            "$mainMod SHIFT, K, swapnext, prev"
            "$mainMod SHIFT, T, togglefloating,"
            "$mainMod, P, exec, rofi -show drun -replace -i -show-icons"
            "$mainMod, backslash, exec, screenshot-region"
            "$mainMod SHIFT, M, exec, toggle-layout"
            "$mainMod, F, fullscreen,1"
            "$mainMod SHIFT, F, fullscreen,0"

            # ─── App launchers ───
            "$mainMod, B, exec, firefox"

            # ─── Fcitx5 ───
            "$mainMod, slash, exec, fcitx5-remote -s keyboard-us"
            "$mainMod SHIFT, slash, exec, fcitx5-remote -s bamboo"

            # ─── Monitor focus ───
            "$mainMod, W, focusmonitor, DP-2"
            "$mainMod, W, focusmonitor, DP-1"
            "$mainMod, E, focusmonitor, eDP-1"

            # ─── Spatial navigation (arrows) ───
            "$mainMod, left, movefocus, l"
            "$mainMod, right, movefocus, r"
            "$mainMod, up, movefocus, u"
            "$mainMod, down, movefocus, d"

            # ─── Quickshell popup toggles ───
            "$mainMod, D, exec, ~/.config/hypr/scripts/qs_manager.sh toggle applauncher"
            "$mainMod, C, exec, ~/.config/hypr/scripts/qs_manager.sh toggle clipboard"
            "$mainMod, V, exec, ~/.config/hypr/scripts/qs_manager.sh toggle volume"
            "$mainMod, N, exec, ~/.config/hypr/scripts/qs_manager.sh toggle network"
            "$mainMod, S, exec, ~/.config/hypr/scripts/qs_manager.sh toggle calendar"
            "$mainMod, Q, exec, ~/.config/hypr/scripts/qs_manager.sh toggle music"
            "$mainMod SHIFT, S, exec, ~/.config/hypr/scripts/qs_manager.sh toggle settings"
            "$mainMod, H, exec, ~/.config/hypr/scripts/qs_manager.sh toggle guide"
            "$mainMod, R, exec, ~/.config/hypr/scripts/reload.sh"

            # ─── Workspaces via quickshell IPC ───
            "$mainMod, 1, exec, ~/.config/hypr/scripts/qs_manager.sh 1"
            "$mainMod, 2, exec, ~/.config/hypr/scripts/qs_manager.sh 2"
            "$mainMod, 3, exec, ~/.config/hypr/scripts/qs_manager.sh 3"
            "$mainMod, 4, exec, ~/.config/hypr/scripts/qs_manager.sh 4"
            "$mainMod, 5, exec, ~/.config/hypr/scripts/qs_manager.sh 5"
            "$mainMod, 6, exec, ~/.config/hypr/scripts/qs_manager.sh 6"
            "$mainMod, 7, exec, ~/.config/hypr/scripts/qs_manager.sh 7"
            "$mainMod, 8, exec, ~/.config/hypr/scripts/qs_manager.sh 8"
            "$mainMod, 9, exec, ~/.config/hypr/scripts/qs_manager.sh 9"
            "$mainMod, 0, exec, ~/.config/hypr/scripts/qs_manager.sh 10"
            "$mainMod SHIFT, 1, exec, ~/.config/hypr/scripts/qs_manager.sh 1 move"
            "$mainMod SHIFT, 2, exec, ~/.config/hypr/scripts/qs_manager.sh 2 move"
            "$mainMod SHIFT, 3, exec, ~/.config/hypr/scripts/qs_manager.sh 3 move"
            "$mainMod SHIFT, 4, exec, ~/.config/hypr/scripts/qs_manager.sh 4 move"
            "$mainMod SHIFT, 5, exec, ~/.config/hypr/scripts/qs_manager.sh 5 move"
            "$mainMod SHIFT, 6, exec, ~/.config/hypr/scripts/qs_manager.sh 6 move"
            "$mainMod SHIFT, 7, exec, ~/.config/hypr/scripts/qs_manager.sh 7 move"
            "$mainMod SHIFT, 8, exec, ~/.config/hypr/scripts/qs_manager.sh 8 move"
            "$mainMod SHIFT, 9, exec, ~/.config/hypr/scripts/qs_manager.sh 9 move"
            "$mainMod SHIFT, 0, exec, ~/.config/hypr/scripts/qs_manager.sh 10 move"

            "$mainMod, space, exec, toggle-special"
            "$mainMod SHIFT, space, movetoworkspacesilent, special:term"

            "$mainMod, mouse_down, workspace, e+1"
            "$mainMod, mouse_up, workspace, e-1"
          ];

          # SwayOSD + media key binds
          bindl = [
            ", Caps_Lock, exec, sleep 0.1 && swayosd-client --caps-lock"
            ", XF86MonBrightnessDown, exec, swayosd-client --brightness lower"
            ", XF86MonBrightnessUp, exec, swayosd-client --brightness raise"
            ", Print, exec, ~/.config/hypr/scripts/screenshot.sh"
            "SHIFT, Print, exec, ~/.config/hypr/scripts/screenshot.sh --edit"
            "SUPER, Print, exec, ~/.config/hypr/scripts/screenshot.sh --full"
            ", XF86AudioPause, exec, playerctl play-pause"
            ", XF86AudioPlay, exec, playerctl play-pause"
            ", xf86AudioMicMute, exec, swayosd-client --input-volume mute-toggle"
            ", xf86audiomute, exec, swayosd-client --output-volume mute-toggle"
            ", XF86PowerOff, exec, systemctl suspend"
          ];

          bindel = [
            ", xf86audiolowervolume, exec, swayosd-client --output-volume lower"
            ", xf86audioraisevolume, exec, swayosd-client --output-volume raise"
          ];

          binde = [
            "$mainMod SHIFT, left, resizeactive, -50 0"
            "$mainMod SHIFT, right, resizeactive, 50 0"
            "$mainMod SHIFT, up, resizeactive, 0 -50"
            "$mainMod SHIFT, down, resizeactive, 0 50"
          ];

          bindm = mkForce [
            "$mainMod, mouse:272, movewindow"
            "$mainMod, mouse:273, resizewindow"
          ];
        }
      ];

      # Source colors.conf BEFORE settings (sourceFirst=true puts extraConfig first)
      # Also define quickshell passthru submap
      wayland.windowManager.hyprland.extraConfig = ''
        source = ~/.config/hypr/colors.conf

        submap = passthru
        bind = SUPER SHIFT CTRL ALT, F35, exec, true
        submap = reset
      '';
    })
  ]);
}
