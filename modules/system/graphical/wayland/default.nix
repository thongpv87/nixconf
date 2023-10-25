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
  environment.systemPackages = with pkgs; [
    grim
    qt5.qtwayland
    slurp
    swaybg
    wl-clipboard
    (wofi.overrideAttrs (_: {
      preFixup = ''
        gappsWrapperArgs+=(
          --add-flags '-c ${./wofi/config}'
          --add-flags '-s ${./wofi/style.css}'
        )
      '';
    }))
    wofi-emoji
  ];
  programs.tmux.extraConfig = lib.mkBefore ''
    set -g @override_copy_command 'wl-copy'
  '';

    xdg = {
      portal = {
        enable = true;
        wlr.enable = ! config.programs.hyprland.enable;
        wlr.settings.screencast.force_mod_linear = true;
        extraPortals = with pkgs; [ xdg-desktop-portal-gtk ];
      };
    };
    # security.pam.services.swaylock = true;
    # security.pam.services.waylock = true;
  };
}
