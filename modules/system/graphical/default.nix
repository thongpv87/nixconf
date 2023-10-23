{ config, pkgs, lib, ... }:
let
  cfg = config.nixconf.graphical;
  inherit (lib)
    mkOption mkMerge mkIf mkDefault mkForce types mdDoc mkEnableOption;
in {
  imports = [ ./xorg ];
  options.nixconf.graphical = {
    enable = mkEnableOption "Enable graphical desktop environment";
    desktopEnv = mkOption { type = types.enum [ "xmonad" "hyprland" ]; };
  };

  config = lib.mkMerge [
    (mkIf (cfg.desktopEnv == "xmonad") {
      nixconf.graphical.xorg = {
        enable = true;
        xmonad.enable = true;
      };
    })
  ];
}
