{ pkgs, config, lib, modulesPath, ... }:
let cfg = config.nixconf.hardware.elitebook-845g10;
in {
  options.nixconf.hardware.virtualbox = {
    enable = lib.mkOption { default = false; };
  };

  imports = [ "${modulesPath}/virtualisation/virtualbox-guest.nix" ];

  config = lib.mkIf cfg.enable {
    boot.growPartition = true;
    virtualisation.virtualbox.guest.enable = true;
  };
}
