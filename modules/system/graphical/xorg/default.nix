{ config, pkgs, lib, ... }:
let
  cfg = config.nixconf.graphical.xorg;
  inherit (lib)
    mkOption mkMerge mkIf mkDefault mkForce types mdDoc mkEnableOption;
in {
  imports = [ ./xmonad ];
  options.nixconf.graphical.xorg = {
    enable = mkEnableOption "Enable xorg desktop server";
  };

  config = mkIf cfg.enable {
    services = {
      xserver = {
        enable = true;
        libinput = { enable = true; };
        xkbOptions = "caps:escape";
      };
    };

    console.useXkbConfig = true;
  };
}
