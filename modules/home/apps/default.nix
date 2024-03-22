{ pkgs, config, lib, ... }:
with lib;
let cfg = config.nixconf.apps;
in {
  imports = [ ./emacs ./rofi ./wal ./alacritty ];

  options.nixconf.apps = {
    enable = mkOption {
      description = "Enable a set of common applications";
      type = types.bool;
      default = false;
    };
  };

  config = mkIf (cfg.enable) { home.packages = [ pkgs.insomnia ]; };
}
