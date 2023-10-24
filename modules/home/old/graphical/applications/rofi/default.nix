{ config, lib, pkgs, ... }:
with lib;
let cfg = config.nixconf.old.graphical.applications.rofi;
in {
  options.nixconf.old.graphical.applications.rofi = {
    enable = mkOption { default = false; };

    profile = mkOption {
      type = with types; enum [ "simple" ];
      default = "simple";
      description = ''
        rofi theme"
      '';
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      home.packages = [ pkgs.rofi pkgs.noto-fonts-extra ];

      xdg = {
        configFile = {
          "rofi" = {
            source = ./rofi/1080p;
            recursive = true;
          };
        };

        dataFile = {
          "fonts" = {
            source = ./rofi/fonts;
            recursive = true;
          };
        };
      };

      home.activation = {
        myActivationAction = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          cp $HOME/.config/rofi/powermenu/styles/colors.rasi.in $HOME/.config/rofi/powermenu/styles/colors.rasi
          chmod 600 $HOME/.config/rofi/powermenu/styles/colors.rasi
        '';
      };
    }

    (mkIf (cfg.profile == "simple") { })
  ]);
}
