{ pkgs, config, lib, modulesPath, ... }:
let cfg = config.nixconf.hardware.thinkpad-x1e2;
in {
  options.nixconf.hardware.thinkpad-x1e2 = {
    enable = lib.mkOption { default = false; };
  };

  imports = [ "${modulesPath}/virtualisation/virtualbox-guest.nix" ];
  config = lib.mkIf cfg.enable {
    boot.growPartition = true;
    virtualisation.virtualbox.guest.enable = true;
  };
}
