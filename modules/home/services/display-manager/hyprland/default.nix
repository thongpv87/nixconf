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
        class="warning"
        printf '{"text": "󰒲 %ds", "tooltip": "Suspend in %d seconds", "class": "%s"}\n' "$remaining" "$remaining" "$class"
      else
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
    ext_monitor=$(hyprctl monitors -j | ${pkgs.jq}/bin/jq -r '.[] | select(.name | startswith("eDP") | not) | .name' | head -1)

    if [ -z "$ext_monitor" ]; then
      exit 0
    fi

    ext_x=$(hyprctl monitors -j | ${pkgs.jq}/bin/jq -r ".[] | select(.name == \"$ext_monitor\") | .x")
    if [ "$ext_x" -lt -2000 ] 2>/dev/null; then
      current="side"
    else
      current="above"
    fi

    if [ "$current" = "side" ]; then
      hyprctl keyword monitor "eDP-1,2560x1600@120,0x0,1.33,vrr,2"
      hyprctl keyword monitor "$ext_monitor,3440x1440@120,-920x-1440,1,bitdepth,10,vrr,2"
      echo "above" > "$STATE_FILE"
    else
      hyprctl keyword monitor "eDP-1,2560x1600@120,0x0,1.33,vrr,2"
      hyprctl keyword monitor "$ext_monitor,3440x1440@120,-3440x-440,1,bitdepth,10,vrr,2"
      echo "side" > "$STATE_FILE"
    fi

    systemctl --user restart waybar
  '';

  monitor-scale = pkgs.writeShellScriptBin "monitor-scale" ''
    apply_config() {
      ext_monitor=$(hyprctl monitors -j | ${pkgs.jq}/bin/jq -r '.[] | select(.name | startswith("eDP") | not) | .name' | head -1)

      if [ -n "$ext_monitor" ]; then
        hyprctl keyword monitor "eDP-1,2560x1600@120,0x0,1.33,vrr,2"
        layout=$(cat /tmp/hypr-layout-mode 2>/dev/null || echo "side")
        if [ "$layout" = "above" ]; then
          hyprctl keyword monitor "$ext_monitor,3440x1440@120,-920x-1440,1,bitdepth,10,vrr,2"
        else
          layout="side"
          hyprctl keyword monitor "$ext_monitor,3440x1440@120,-3440x-440,1,bitdepth,10,vrr,2"
        fi
        echo "$layout" > /tmp/hypr-layout-mode
      else
        hyprctl keyword monitor "eDP-1,2560x1600@120,0x0,1,vrr,2"
      fi
    }

    sleep 0.5
    apply_config

    ${pkgs.socat}/bin/socat -U - UNIX-CONNECT:"$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" | while read -r line; do
      case "$line" in
        monitoradded*|monitorremoved*)
          sleep 0.5
          apply_config
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

  workspace-action = pkgs.writeShellScriptBin "workspace-action" ''
    TARGET_WS=$1
    CURRENT_WS=$(hyprctl activeworkspace -j | ${pkgs.jq}/bin/jq -r ".id")
    CURRENT_MON=$(hyprctl activeworkspace -j | ${pkgs.jq}/bin/jq -r ".monitor")
    TARGET_MON=$(hyprctl workspaces -j | ${pkgs.jq}/bin/jq -r ".[] | select(.id == $TARGET_WS) | .monitor")
    
    if [ -n "$TARGET_MON" ] && [ "$TARGET_MON" != "null" ] && [ "$TARGET_MON" != "$CURRENT_MON" ]; then
      IS_ACTIVE=$(hyprctl monitors -j | ${pkgs.jq}/bin/jq -r ".[] | select(.name == \"$TARGET_MON\") | .activeWorkspace.id")
      if [ "$IS_ACTIVE" == "$TARGET_WS" ]; then
        # It is active on the other monitor, so swap them
        hyprctl dispatch swapactiveworkspaces "$CURRENT_MON" "$TARGET_MON"
        exit 0
      fi
    fi
    
    # Otherwise just pull it to current monitor
    hyprctl --batch "dispatch moveworkspacetomonitor $TARGET_WS current ; dispatch workspace $TARGET_WS"
  '';

in
{
  options.nixconf.services.display-manager.hyprland = {
    enable = mkEnableOption "Enable Hyprland display server";

    defaultLayout = mkOption {
      type = types.enum [ "master" "dwindle" "scrolling" ];
      default = "scrolling";
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
    ./shells/classic.nix
    ./shells/quickshell
  ];

  config = mkIf cfg.enable {
    nixconf.apps.rofi.enable = true;

    home.sessionVariables = {
      QT_QPA_PLATFORM = "wayland";
      XDG_SESSION_DESKTOP = "Hyprland";
      XDG_CURRENT_DESKTOP = "Hyprland";
    };

    home.packages = with pkgs; [
      inotify-tools
      switch-input-method
      screenshot-region
      toggle-special
      cycle-hypr-layout
      toggle-layout
      workspace-action
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

    xdg.configFile = {
      "dunst" = {
        source = ./dunst;
        recursive = true;
      };
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

    gtk.gtk3.extraConfig = {};
    gtk.gtk4.extraConfig = {};

    wayland.windowManager.hyprland = {
      enable = true;
      configType = "hyprlang";
      package = null;
      portalPackage = null;
      systemd = {
        enable = true;
        variables = [ "--all" ];
        enableXdgAutostart = true;
      };
      xwayland.enable = true;

      settings = {
        decoration = import ./decorations/${cfg.decoration}.nix;

        exec-once = [
          "dbus-update-activation-environment --systemd --all"
          "fcitx5 -d --replace"
          "monitor-scale"
          "${pkgs.wl-clipboard}/bin/wl-paste --watch ${pkgs.cliphist}/bin/cliphist store"
          "hypridle"
        ];

        general = {
          snap.enabled = true;
          layout = cfg.defaultLayout;
        };

        monitor = builtins.map (m:
          "${m}, 3440x1440@120,-3440x-440,1,bitdepth,10,vrr,2"
        ) [ "DP-1" "DP-2" ] ++ [
          "eDP-1,2560x1600@120,0x0,1.33,vrr,2"
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

        scrolling = {
          fullscreen_on_one_column = true;
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

          "$mod, J, cyclenext"
          "$mod, K, cyclenext, prev"
          "$mod SHIFT, J, swapnext"
          "$mod SHIFT, K, swapnext, prev"

          "$mod, T, togglefloating,"
          "$mod, backslash, exec, screenshot-region"
          "$mod SHIFT, M, exec, toggle-layout"
          "$mod, F, fullscreen,1"
          "$mod SHIFT, F, fullscreen,0"

          "$mod, B, exec, firefox"
          "$mod, D, exec, nautilus"

          ",121,exec, pamixer --toggle-mute"
          ",122,exec, pamixer -d 5"
          ",123,exec, pamixer -i 5"

          "$mod,slash, exec, fcitx5-remote -s keyboard-us"
          "$mod SHIFT, slash, exec, fcitx5-remote -s bamboo"

          "$mod,W, focusmonitor, DP-2"
          "$mod,W, focusmonitor, DP-1"
          "$mod,E, focusmonitor,eDP-1"

          "$mod, left, movefocus, l"
          "$mod, right, movefocus, r"
          "$mod, up, movefocus, u"
          "$mod, down, movefocus, d"
          "$mod SHIFT, left, resizeactive, -40 0"
          "$mod SHIFT, right, resizeactive, 40 0"
          "$mod SHIFT, up, resizeactive, 0 -40"
          "$mod SHIFT, down, resizeactive, 0 40"

        ] ++ (
          builtins.concatLists (builtins.map (i: [
            "$mod, ${i}, exec, workspace-action ${if i == "0" then "10" else i}"
            "$mod SHIFT, ${i}, movetoworkspacesilent, ${if i == "0" then "10" else i}"
          ]) [ "1" "2" "3" "4" "5" "6" "7" "8" "9" "0" ])
        ) ++ [
          "$mod, space, exec, toggle-special"
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
          "XMODIFIERS,@im=fcitx"
        ];

        debug = {
          vfr = true;
        };
      };
    };
  };
}
