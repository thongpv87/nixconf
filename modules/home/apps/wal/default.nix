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
  options.nixconf.apps.wal = {
    enable = mkOption { default = false; };
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.noto-fonts ];

    programs.pywal.enable = false;

    xdg = {
      configFile = {
        "wal/templates" = {
          source = ./templates;
          recursive = true;
        };
      };
    };
  };
}
