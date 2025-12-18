{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.nixconf.apps.rofi;
in
{
  options.nixconf.apps.rofi = {
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
      home.packages = [ pkgs.noto-fonts ];

      programs.rofi = {
        enable = true;
      };

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
