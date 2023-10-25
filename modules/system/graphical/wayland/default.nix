{ config, pkgs, lib, ... }:
let
  cfg = config.nixconf.graphical.wayland;
  inherit (lib)
    mkOption mkMerge mkIf mkDefault mkForce types mdDoc mkEnableOption;
in {
  imports = [ ./hyprland.nix ];
  options.nixconf.graphical.wayland = {
    enable = mkEnableOption "Enable xorg desktop server";
  };

  config = mkIf cfg.enable {
    xdg = {
      portal = {
        enable = true;
        wlr.enable = true;
        extraPortals = with pkgs; [ xdg-desktop-portal-gtk ];
      };
    };

    # security.pam.services.swaylock = true;
    # security.pam.services.waylock = true;
  };
}
