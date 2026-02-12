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

  toggle-layout = pkgs.writeShellScriptBin "toggle-layout" ''
    STATE_FILE="/tmp/hypr-layout-mode"
    current=$(cat "$STATE_FILE" 2>/dev/null || echo "side")

    # Find which external monitor is connected
    has_dp1=$(hyprctl monitors -j | ${pkgs.jq}/bin/jq '[.[] | select(.name == "DP-1")] | length')
    has_dp2=$(hyprctl monitors -j | ${pkgs.jq}/bin/jq '[.[] | select(.name == "DP-2")] | length')

    if [ "$has_dp1" -eq 0 ] && [ "$has_dp2" -eq 0 ]; then
      exit 0
    fi

    if [ "$current" = "side" ]; then
      # Switch to above layout
      # eDP-1 logical @1.6: 1600x1000, centered: -920 = (1600 - 3440) / 2
      if [ "$has_dp1" -gt 0 ]; then
        hyprctl keyword monitor "eDP-1,2560x1600@120,0x0,1.6,vrr,1"
        hyprctl keyword monitor "DP-1,3440x1440@120,-920x-1440,1,bitdepth,10,vrr,1"
      elif [ "$has_dp2" -gt 0 ]; then
        hyprctl keyword monitor "eDP-1,2560x1600@120,0x0,1.6,vrr,1"
        hyprctl keyword monitor "DP-2,3440x1440@120,-920x-1440,1,bitdepth,10,vrr,1"
      fi
      echo "above" > "$STATE_FILE"
    else
      # Switch to side layout (laptop right, bottom-aligned)
      # eDP-1 logical @1.6: 1600x1000, bottom-aligned: -440 = 1000 - 1440
      if [ "$has_dp1" -gt 0 ]; then
        hyprctl keyword monitor "eDP-1,2560x1600@120,0x0,1.6,vrr,1"
        hyprctl keyword monitor "DP-1,3440x1440@120,-3440x-440,1,bitdepth,10,vrr,1"
      elif [ "$has_dp2" -gt 0 ]; then
        hyprctl keyword monitor "eDP-1,2560x1600@120,0x0,1.6,vrr,1"
        hyprctl keyword monitor "DP-2,3440x1440@120,-3440x-440,1,bitdepth,10,vrr,1"
      fi
      echo "side" > "$STATE_FILE"
    fi

    # Restart waybar to pick up new monitor layout
    systemctl --user restart waybar
  '';

  monitor-scale = pkgs.writeShellScriptBin "monitor-scale" ''
    apply_config() {
      has_dp1=$(hyprctl monitors -j | ${pkgs.jq}/bin/jq '[.[] | select(.name == "DP-1")] | length')
      has_dp2=$(hyprctl monitors -j | ${pkgs.jq}/bin/jq '[.[] | select(.name == "DP-2")] | length')

      if [ "$has_dp1" -gt 0 ]; then
        # DP-1: laptop right of external, bottom-aligned, scale 1.6
        # eDP-1 logical @1.6: 1600x1000, DP-1: 3440x1440
        # Bottom-aligned: -440 = 1000 - 1440
        hyprctl keyword monitor "eDP-1,2560x1600@120,0x0,1.6,vrr,1"
        hyprctl keyword monitor "DP-1,3440x1440@120,-3440x-440,1,bitdepth,10,vrr,1"
      elif [ "$has_dp2" -gt 0 ]; then
        # DP-2: external above laptop, centered, scale 1.6
        # eDP-1 logical @1.6: 1600x1000
        # Centered: -920 = (1600 - 3440) / 2
        hyprctl keyword monitor "eDP-1,2560x1600@120,0x0,1.6,vrr,1"
        hyprctl keyword monitor "DP-2,3440x1440@120,-920x-1440,1,bitdepth,10,vrr,1"
      else
        # Single monitor, scale 1.0
        hyprctl keyword monitor "eDP-1,2560x1600@120,0x0,1,vrr,1"
      fi
    }

    # Apply on startup
    sleep 1
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

in
{
  options.nixconf.services.display-manager.hyprland = {
    enable = mkEnableOption "Enable Hyprland display server";

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
        toggle-layout
        monitor-scale
        wl-clipboard
        cliphist
        pamixer
        dunst
        qt5.qtwayland
        qt6.qtwayland
        nautilus
        btop
        wlr-randr
        # hypridle
        # hyprlock
        pavucontrol
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
        "hypr/hypridle.conf".source = ./hypridle.conf;
        "hypr/hyprlock.conf".source = ./hyprlock.conf;
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
        systemd.enable = true;
        # systemd.enableXdgAutoStart = true;
        xwayland.enable = true;
        # systemd.extraCommands = [ "ibus-deamon -d" ];

        settings = {
          exec-once = [
            # "ibus-daemon -d"
            "fcitx5 -r"
            "${pkgs.dunst}/bin/dunst"
            "monitor-scale"
            "${pkgs.wl-clipboard}/bin/wl-paste --watch ${pkgs.cliphist}/bin/cliphist store"
            #"hypridle"
          ];

          general = {
            snap.enabled = true;
          };
          monitor = [
            "eDP-1,2560x1600@120,0x0,1,vrr,1"
            "DP-1, 3440x1440@120,-3440x160,1,bitdepth,10,vrr,1" # P34WD-40 - laptop to the right, bottom-aligned
            "DP-2, 3440x1440@120,-440x-1440,1,bitdepth,10,vrr,1" # P34WD-40 - external above, centered
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

          #color scheme config
          #
          dwindle = {
            # See https://wiki.hyprland.org/Configuring/Dwindle-Layout/ for more
            pseudotile = true; # master switch for pseudotiling. Enabling is bound to mainMod + P in the keybinds section below
            preserve_split = true; # you probably want this
          };

          master = {
            # See https://wiki.hyprland.org/Configuring/Master-Layout/ for more
            new_status = "master";
            new_on_top = false;
            new_on_active = "after";
            special_scale_factor = 0.85;
            orientation = "right";
          };

          "$mod" = "SUPER";

          workspace = [ ];

          windowrule = [
            # "tile,class:^(Microsoft-edge)$"
            # "tile,class:^(Brave-browser)$"
            # "tile,class:^(Chromium)$"
            "match:class ^(org.pulseaudio.pavucontrol), float on, size 800 800"
            "match:class ^(blueman-manager)$, float on"
            "match:class ^(nm-connection-editor)$, float on"
            "match:class (Rofi), stay_focused on"
            "match:class ^(firefox|google-chrome|microsoft-edge), opacity 1 1"

          ];
          layerrule = [
            "blur on, match:namespace gtk-layer-shell"
            "blur on, match:namespace logout_dialog"
          ];

          bind = [
            "$mod SHIFT, RETURN, exec, alacritty"
            "$mod SHIFT, C, killactive,"
            "$mod, Q, exec, systemctl suspend"
            "$mod SHIFT, Q, exec, systemctl suspend"
            "$mod, m, layoutmsg, focusmaster"
            "$mod, RETURN, layoutmsg, swapwithmaster"

            "$mod, J, layoutmsg, cyclenext"
            "$mod, K, layoutmsg, cycleprev"
            "$mod SHIFT,J,layoutmsg,swapnext"
            "$mod SHIFT,K,layoutmsg,swapprev"

            "$mod, T, togglefloating,"
            # "$mod, P, exec, wofi --show drun"
            "$mod, P, exec, rofi -show drun -replace -i -show-icons"
            "$mod, I, pseudo," # dwindle
            "$mod, U, togglesplit," # dwindle
            "$mod, backslash, exec, screenshot-region"
            "$mod, V, exec, ${pkgs.cliphist}/bin/cliphist list | rofi -dmenu -p clipboard -i | ${pkgs.cliphist}/bin/cliphist decode | ${pkgs.wl-clipboard}/bin/wl-copy"
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

            # "$mod,slash, exec, ibus engine xkb:us::eng"
            # "$mod SHIFT, slash, exec, ibus engine Bamboo"
            "$mod,slash, exec, fcitx5-remote -s keyboard-us"
            "$mod SHIFT, slash, exec, fcitx5-remote -s bamboo"

            "$mod,W, focusmonitor, DP-2"
            "$mod,W, focusmonitor, DP-1"
            "$mod,E, focusmonitor,eDP-1"

            # Move focus with mod + arrow keys
            "$mod, left, movewindow, l"
            "$mod, right, movewindow, r"
            "$mod, up, movewindow, u"
            "$mod, down, movewindow, d"
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
            "$mod SHIFT, space, movetoworkspacesilent, special"

            # # Scroll through existing workspaces with mod + scroll
            "$mod, mouse_down, workspace, e+1"
            "$mod, mouse_up, workspace, e-1"
          ];
          # Move/resize windows with mod + LMB/RMB and dragging
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
            vfr = true;
          };
        };
      };
    }

    {
      wayland.windowManager.hyprland.extraConfig = ''
        # Execute your favorite apps at launch
        # Source a file (multi-file configs)
        env = GDK_BACKEND=wayland,x11
        env = QT_QPA_PLATFORM="wayland;xcb"
        env = CLUTTER_BACKEND=wayland
        env = QT_AUTO_SCREEN_SCALE_FACTOR=1
        env = QT_WAYLAND_DISABLE_WINDOWDECORATION=1
        source = /home/thongpv87/.cache/wal/colors-hyprland.conf
        source = ${./decorations}/${cfg.decoration}.conf
        source = ${./animations}/${cfg.animation}.conf
        source = ${./windows}/${cfg.window}.conf
      '';
    }
  ]);
}
