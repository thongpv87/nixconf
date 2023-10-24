{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.nixconf.old.graphical.xorg.xmonad.simple;

  shellScripts = pkgs.stdenv.mkDerivation {
    name = "myShellScripts";
    src = ./bin;
    phases = "installPhase";
    installPhase = ''
      mkdir -p $out/bin
      cp -r ${./bin}/* $out/bin/
      chmod +x $out/bin/*
    '';
  };
in {
  options.nixconf.old.graphical.xorg.xmonad.simple = {
    enable = mkOption { default = false; };
  };

  config = mkIf cfg.enable (mkMerge [{
    home.packages = with pkgs; [
      wmctrl
      acpi
      playerctl
      jq
      xclip
      maim
      xautolock
      betterlockscreen
      feh
      xdotool
      scrot
      font-awesome
      selected-nerdfonts
      rofi
      libqalculate
      brightnessctl
      xorg.xbacklight
      xorg.setxkbmap
      dunst
      font-awesome
      selected-nerdfonts
      gnome.gnome-terminal
      shellScripts
      trayer
      #statusbar
      alsa-utils
      networkmanagerapplet
      imagemagick
      #jonaburg-picom
    ];

    xsession = {
      enable = true;

      windowManager = {
        xmonad = {
          enable = true;
          enableContribAndExtras = true;
          config = ./xmonad.hs;
        };
      };
    };

    systemd.user.services.dunst = {
      Unit = {
        Description = "Dunst notification daemon";
        After = [ "graphical-session-pre.target" ];
        PartOf = [ "graphical-session.target" ];
      };

      Service = {
        Type = "dbus";
        BusName = "org.freedesktop.Notifications";
        ExecStart = "${pkgs.dunst}/bin/dunst";
      };
    };

    xdg = {
      configFile = {
        #"picom/picom.conf".source = ./config/picom.conf;
        "dunst" = {
          source = ./dunst;
          recursive = true;
        };

        "alacritty/alacritty.yml.in".source = ./alacritty/alacritty.yml;
      };
    };

    services = {
      random-background = {
        enable = true;
        enableXinerama = true;
        display = "fill";
        imageDirectory = "%h/Pictures/Wallpapers";
        interval = "24h";
      };

      picom = {
        enable = false;

        #vSync = true;

        #activeOpacity = "1";
        #inactiveOpacity = "0.9";
        opacityRules = [
          "100:class_g   *?= 'Chromium-browser'"
          "100:class_g   *?= 'Google-Chrome'"
          "100:class_g   *?= 'zoom'"
          "100:class_g   *?= 'Firefox'"
          "100:class_g   *?= 'Alacritty'"
          "100:name      *?= 'Dunst'"
          "100:class_g   *?= 'gitkraken'"
          "100:name      *?= 'emacs'"
          "100:class_g   *?= 'emacs'"
          "100:class_g   ~=  'jetbrains'"
          "100:class_g   *?= 'rofi'"
          "70:name       *?= 'GLava'"
          "70:name       *?= 'GLavaRadial'"
        ];

        settings = {
          corner-radius = 12;
          xinerama-shadow-crop = true;
          #blur-background = true;
          #blur-method = "kernel";
          #blur-strength = 5;
          rounded-corners-exclude = {
            #window_type = "normal";
            class_g = [
              "Rofi"
              "Polybar"
              "code-oss"
              "trayer"
              "Thunderbird"
              #"xmobar"
              #"Alacritty"
              #"firefox"
            ];

            name = [ "Notification area" "xmobar" ];
          };
        };

        shadowExclude = [ "bounding_shaped && !rounded_corners" ];

        fade = true;
        fadeDelta = 10;
      };
    };
  }]);
}
