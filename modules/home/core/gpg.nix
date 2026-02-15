{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.nixconf.core.gpg;
in
{
  options.nixconf.core.gpg = {
    enable = mkOption {
      description = "Enable gpg";
      type = types.bool;
      default = false;
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.pinentry-curses ];

    programs.gpg = {
      enable = true;
      homedir = "${config.xdg.dataHome}/gnupg";
    };

    services.gpg-agent = {
      enable = true;
      pinentry.package = pkgs.pinentry-curses;
      enableExtraSocket = true;
      enableScDaemon = false;
    };
  };
}
