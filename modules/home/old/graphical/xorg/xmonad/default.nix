{ config, lib, pkgs, ... }:

with lib;
let cfg = config.nixconf.old.graphical.xorg.xmonad;
in {
  options.nixconf.old.graphical.xorg.xmonad = {
    enable = mkOption {
      default = false;
      description = ''
        Whether to enable xmonad bundle
      '';
    };

    theme = mkOption {
      type = with types; enum [ "simple" ];
      default = "simple";
      description = ''
        xmonad theme"
      '';
    };
  };

  imports = [ ./simple ];

  config = mkIf cfg.enable (mkMerge [
    {
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
        xmobar
      ];

      programs = { autorandr = { enable = true; }; };

      systemd.user.services = {
        xsettings = {
          Unit.Description = "xsettings daemon";
          Service = {
            ExecStart =
              "${pkgs.gnome.gnome-settings-daemon}/libexec/gsd-xsettings";
            Restart = "on-failure";
            RestartSec = 3;
          };

          Install.WantedBy = [ "graphical-session.target" ];
        };
      };
    }

    (mkIf (cfg.theme == "simple") {
      nixconf.old.graphical.xorg.xmonad.simple.enable = true;
    })

  ]);
}
