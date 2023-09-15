{ pkgs, config, lib, ... }:
with lib;
let cfg = config.nixconf.apps;
in {
  # imports = [ ./emacs ];

  options.thongpv87.apps = {
    enable = mkOption {
      description = "Enable a set of common applications";
      type = types.bool;
      default = false;
    };
  };

  config = mkIf (cfg.enable) { };
}
