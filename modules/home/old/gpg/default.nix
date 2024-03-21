{ pkgs, config, lib, ... }:
with lib;
let cfg = config.nixconf.old.gpg;
in {
  options.nixconf.old.gpg = {
    enable = mkOption {
      description = "enable gpg";
      type = types.bool;
      default = false;
    };
  };

  config = mkIf (cfg.enable) {
    home.packages = with pkgs; [ pinentry-curses];

    programs.gpg = {
      enable = true;
      homedir = "${config.xdg.dataHome}/gnupg";
    };

    services.gpg-agent = {
      enable = true;
      pinentryPackage = pkgs.pinentry-curses;
      enableExtraSocket = true;
      enableScDaemon = false;
    };
  };
}
