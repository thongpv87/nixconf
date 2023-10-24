{ config, lib, pkgs, ... }:
with lib;
let cfg = config.nixconf.old.others.develop.agda;
in {
  options = {
    thongpv87.others.develop.agda.enable = mkOption { default = false; };
  };

  config =
    mkIf cfg.enable { home.packages = with pkgs.agdaPackages; [ agda ]; };
}
