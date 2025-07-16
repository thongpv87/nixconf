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
    ${pkgs.grim}/bin/grim -g "$(${pkgs.slurp}/bin/slurp)"
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
    ./quickshell
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
        pamixer
        dunst
        qt5.qtwayland
        qt6.qtwayland
        nautilus
        btop
        # hypridle
        # hyprlock
        hyprpaper
        pavucontrol
      ];

      fonts.fontconfig.enable = true;
      services.copyq = {
        enable = true;
      };

      xdg.configFile = {
        "dunst" = {
          source = ./dunst;
          recursive = true;
        };
        "hypr/hypridle.conf".source = ./hypridle.conf;
        "hypr/hyprlock.conf".source = ./hyprlock.conf;
        "hypr/hyprpaper.conf".text =
          let
            pic = "peaceful-autumn.jpg";
          in
          ''
            preload = ${./wallpapers}/${pic}
            wallpaper = DP-1,${./wallpapers}/${pic}
            wallpaper = DP-2,${./wallpapers}/${pic}
            wallpaper = eDP-1,${./wallpapers}/${pic}
          '';
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
        # GTK_IM_MODULE="ibus";
        # QT_IM_MODULE="ibus";
        # XMODIFIERS="@im=ibus";
        # SDL_IM_MODULE="ibus";
        # GLFW_IM_MODULE="ibus";

        GTK_IM_MODULE = "fcitx";
        QT_IM_MODULE = "fcitx";
        XMODIFIERS = "@im=fcitx";
        SDL_IM_MODULE = "fcitx";
        GLFW_IM_MODULE = "fcitx";
        QT_IM_MODULES = "wayland;fcitx;ibus";
      };

      gtk.gtk3.extraConfig = {
        gtk-im-module = "fcitx";
      };

      gtk.gtk4.extraConfig = {
        gtk-im-module = "fcitx";
      };

      wayland.windowManager.hyprland = {
        enable = true;
        systemd.enable = false; # it conflicts with uwsm.
        # systemd.enableXdgAutoStart = true;
        xwayland.enable = true;
        # systemd.extraCommands = [ "ibus-deamon -d" ];

        settings = {
          exec-once = [
            # "ibus-daemon -d"
            "fcitx5 -r"
            "${pkgs.dunst}/bin/dunst"
            #"hypridle"
            "hyprpaper"
            #"${pkgs.wpaperd}/bin/wpaperd"
          ];

          general = {
            snap.enabled = true;
          };
          monitor = [
            #"eDP-1,2560x1600@120,640x1440,1"
            # "DP-1,3840x2160@60,0x0,1,bitdepth,10" #U2720Q
            "eDP-1,2560x1600@120,440x1440,1,vrr,1"
            "DP-1, 3440x1440@120,0x0,1,bitdepth,10,vrr,1" # P34WD-40
            "DP-2, 3440x1440@120,0x0,1,bitdepth,10,vrr,1" # P34WD-40
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
            inherit_fullscreen = true;
            orientation = "right";
          };

          gestures = {
            workspace_swipe = true;
          };

          "$mod" = "SUPER";

          workspace = [ "special, on-created-empty:alacritty" ];

          windowrule = [
            "tile,class:^(Microsoft-edge)$"
            "tile,class:^(Brave-browser)$"
            "tile,class:^(Chromium)$"
            "float,class:^(pavucontrol)$"
            "float,class:^(blueman-manager)$"
            "float,class:^(nm-connection-editor)$"
            "stayfocused,class:(Rofi)"
            "opacity 1 1,class:^(firefox|google-chrome|microsoft-edge)"

          ];
          layerrule = [
            "blur, gtk-layer-shell"
            "blur, logout_dialog"
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
            "$mod, P, exec, rofi -config ~/.cache/wal/colors-rofi-light.rasi -show drun -replace -i"
            "$mod, I, pseudo," # dwindle
            "$mod, U, togglesplit," # dwindle
            "$mod, backslash, exec, screenshot-region"
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
            "$mod, space, togglespecialworkspace,"

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
            new_window_takes_over_fullscreen = 1;
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
        source = ${./extra.conf}
        source = ${./decorations}/${cfg.decoration}.conf
        source = ${./animations}/${cfg.animation}.conf
        source = ${./windows}/${cfg.window}.conf
      '';
    }
  ]);
}
