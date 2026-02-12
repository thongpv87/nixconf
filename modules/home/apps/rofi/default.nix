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
        theme = ./theme.rasi;
      };
    }

    (mkIf (cfg.profile == "simple") { })
  ]);
}
