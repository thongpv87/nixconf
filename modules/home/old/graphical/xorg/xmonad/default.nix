{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.nixconf.old.graphical.xorg.xmonad;

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
  options.nixconf.old.graphical.xorg.xmonad = {
    enable = mkOption { default = false; };
  };

  config = mkIf cfg.enable (mkMerge [{
    home.packages = with pkgs; [
      pop-gtk-theme
      numix-icon-theme
      pop-icon-theme
      papirus-icon-theme
      vlc
      shotwell
      dconf
      glib.bin
      gnome.gnome-tweaks
      gnome.nautilus
      okular
      rhythmbox
      pavucontrol

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
      dunst
      font-awesome
      selected-nerdfonts
      gnome.gnome-terminal
      shellScripts
      trayer
      alsa-utils
      networkmanagerapplet
      imagemagick
    ];

    programs = { autorandr = { enable = true; }; };
    home.file = {
      ".xmonad/xmobar" = {
        source = ./xmobar;
        recursive = true;
      };
    };

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
        Install = { WantedBy = [ "graphical-session.target" ]; };
      };

      xmobar = {
        Unit = {
          Description = "xmobar status bar";
          After = [ "hm-graphical-session.target" ];
          PartOf = [ "graphical-session.target" ];
        };

        Service = {
          ExecStart =
            "${pkgs.xmobar}/bin/xmobar /home/thongpv87/.xmonad/xmobar/doom-one-xmobarrc";
          Restart = "on-failure";
          Slice = "session.slice";
        };
        Install = { WantedBy = [ "graphical-session.target" ]; };
      };

      trayer = {
        Unit = {
          Description = "xmobar status bar";
          After = [ "hm-graphical-session.target" ];
          PartOf = [ "graphical-session.target" ];
        };

        Service = {
          ExecStart =
            "${pkgs.trayer}/bin/trayer --edge top --align right --widthtype request --padding 6 --SetDockType true --SetPartialStrut true --expand true --monitor 1 --transparent true --alpha 0 --tint 0x282c34 --height 22";
          Restart = "on-failure";
          Slice = "session.slice";
        };
        Install = { WantedBy = [ "graphical-session.target" ]; };
      };

      xsettings = {
        Unit.Description = "xsettings daemon";

        Service = {
          ExecStart =
            "${pkgs.gnome.gnome-settings-daemon}/libexec/gsd-xsettings";
          Restart = "on-failure";
          RestartSec = 3;
        };

        Install.WantedBy = [ "hm-graphical-session.target" ];
      };
    };

    xdg = {
      configFile = {
        #"picom/picom.conf".source = ./config/picom.conf;
        "dunst" = {
          source = ./dunst;
          recursive = true;
        };

        "alacritty/alacritty.toml".source = ./alacritty/alacritty.toml;
        #"alacritty/alacritty.yml.in".source = ./alacritty/alacritty.yml;
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
