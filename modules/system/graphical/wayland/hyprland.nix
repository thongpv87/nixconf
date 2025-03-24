{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.nixconf.graphical.wayland.hyprland;
  inherit (lib)
    mkOption
    mkMerge
    mkIf
    mkDefault
    mkForce
    types
    mdDoc
    mkEnableOption
    ;
in
{
  options.nixconf.graphical.wayland.hyprland = {
    enable = mkEnableOption "Enable xorg desktop server";
  };

  config = mkIf cfg.enable {
    programs = {
      dconf.enable = true;
      uwsm.enable = true;
      hyprland = {
        enable = true;
        xwayland.enable = true;
        withUWSM = true;
      };
    };
    security.polkit.enable = true;

    xdg.portal = {
      enable = true;
      xdgOpenUsePortal = true;
      extraPortals = [
        pkgs.xdg-desktop-portal-gtk
        pkgs.xdg-desktop-portal-hyprland
      ];
    };

    environment.sessionVariables = {
      NIXOS_OZONE_WL = "1";
      _JAVA_OPTIONS = "-Dswing.defaultlaf=com.sun.java.swing.plaf.gtk.GTKLookAndFeel";
    };
  };
}
