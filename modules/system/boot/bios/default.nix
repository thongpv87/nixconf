{ config, pkgs, lib, ... }:
let cfg = config.nixconf.boot.bios;
in {
  options.nixconf.boot.bios = {
    enable = lib.mkEnableOption "whether enable BIOS boot";
  };

  config = lib.mkIf cfg.enable {

  };
}
