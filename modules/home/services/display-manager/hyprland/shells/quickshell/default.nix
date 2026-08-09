{ config, pkgs, lib, ... }:
let
  cfg = config.nixconf.services.display-manager.hyprland;
in
lib.mkIf (cfg.enable && cfg.useIlyamiroConfig) {
  nixconf.apps.wal.enable = lib.mkForce false;

  home.packages = with pkgs; [
    quickshell
    matugen
    swww
    mpvpaper
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
    pulseaudio
  ];

  services.swayosd = {
    enable = true;
    topMargin = 0.9;
  };

  xdg.configFile = {
    "hypr/scripts".source = ./scripts;
    "hypr/templates".source = ./templates;
    "matugen".source = ./matugen;
    "cava/config_base".source = ./cava_config;

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

  wayland.windowManager.hyprland.settings = {
    source = [ "~/.config/hypr/colors.conf" ];

    exec-once = [
      "fcitx5-remote -s bamboo"
      "${pkgs.wl-clipboard}/bin/wl-paste --type image --watch ${pkgs.cliphist}/bin/cliphist store"
      "awww-daemon"
      "sleep 2 && if ! awww query 2>/dev/null | grep -q 'displaying:'; then awww img ~/Code/nixconf/modules/home/services/display-manager/hyprland/wallpapers/countryside_landscape.jpg; fi"
      "playerctld"
      "~/.config/hypr/scripts/volume_listener.sh"
    ];

    general = {
      border_size = 2;
      gaps_in = 4;
      gaps_out = 4;
      resize_on_border = true;
      extend_border_grab_area = 30;
      "col.active_border" = "rgba(00d4d9ee) rgba(7aa2f7ee) rgba(bb9af7ee) 45deg";
      "col.inactive_border" = "rgba(313244aa)";
    };

    animations = import ./../../animations/${cfg.animation}.nix;

    misc = {
      font_family = "JetBrains Mono";
    };

    "$mainMod" = "SUPER";

    layerrule = [
      "no_anim on, match:namespace volume_osd"
      "no_anim on, match:namespace brightness_osd"
      "no_anim on, match:namespace hyprpicker"
      "no_anim on, match:namespace qsdock"
      "blur on, match:namespace ext-session-lock"
      "ignore_alpha 0.2, match:namespace ext-session-lock"
    ];

    windowrule = [
      "match:title ^(app-launcher)$, float on, center on, size 1200 600"
    ];

    bind = [
      "$mainMod, V, exec, ~/.config/hypr/scripts/qs_manager.sh toggle clipboard || ${pkgs.cliphist}/bin/cliphist list | rofi -dmenu -p clipboard -i | ${pkgs.cliphist}/bin/cliphist decode | ${pkgs.wl-clipboard}/bin/wl-copy && sleep 0.1 && ${pkgs.wtype}/bin/wtype -M shift -k insert -m shift"
      "$mainMod, A, exec, ~/.config/hypr/scripts/qs_manager.sh toggle volume"
      "$mainMod, N, exec, ~/.config/hypr/scripts/qs_manager.sh toggle network"
      "$mainMod, S, exec, ~/.config/hypr/scripts/qs_manager.sh toggle calendar"
      "$mainMod, M, exec, ~/.config/hypr/scripts/qs_manager.sh toggle music"
      "$mainMod SHIFT, S, exec, ~/.config/hypr/scripts/qs_manager.sh toggle settings"
      "$mainMod, H, exec, ~/.config/hypr/scripts/qs_manager.sh toggle guide"
      "$mainMod SHIFT, W, exec, ~/.config/hypr/scripts/qs_manager.sh toggle wallpaper"
      "$mainMod, R, exec, ~/.config/hypr/scripts/reload.sh"
      "$mainMod, P, exec, ~/.config/hypr/scripts/qs_manager.sh toggle applauncher || rofi -show drun -replace -i -show-icons"
    ];

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
    ];

    bindel = [
      ", xf86audiolowervolume, exec, swayosd-client --output-volume lower"
      ", xf86audioraisevolume, exec, swayosd-client --output-volume raise"
    ];
  };

  wayland.windowManager.hyprland.extraConfig = ''
    submap = passthru
    bind = SUPER SHIFT CTRL ALT, F35, exec, true
    submap = reset
  '';

  systemd.user.services.quickshell = {
    Unit = {
      Description = "Quickshell daemon";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };

    Service = {
      Type = "simple";
      ExecStart = "${pkgs.quickshell}/bin/quickshell -p %h/.config/hypr/scripts/quickshell/Shell.qml";
      Restart = "on-failure";
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
