{ pkgs, config, lib, ... }:
with lib;
let cfg = config.nixconf.old.applications.neomutt;
in {
  options.nixconf.old.applications.neomutt = {
    enable = mkOption {
      description = "Enable neomutt";
      type = types.bool;
      default = false;
    };
  };

  config = mkIf (config.nixconf.old.applications.enable && cfg.enable) {
    programs.neomutt = { enable = true; };
  };
}
