{ config, pkgs, lib, ... }:
let
  cfg = config.nixconf.graphical;
  inherit (lib)
    mkOption mkMerge mkIf mkDefault mkForce types mdDoc mkEnableOption;
in {
  imports = [ ./xorg ./wayland ];
  options.nixconf.graphical = {
    enable = mkEnableOption "Enable graphical desktop environment";
    desktopEnv = mkOption { type = types.enum [ "xmonad" "hyprland" ]; };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      services.xserver.enable = true;
      services.xserver.libinput = {
        enable = true;
        touchpad = {
          disableWhileTyping = true;
          middleEmulation = true;
          tappingButtonMap = "lrm";
        };
      };
    }
    (mkIf (cfg.desktopEnv == "xmonad") {
      nixconf.graphical.xorg = {
        enable = true;
        xmonad.enable = true;
      };
    })
    (mkIf (cfg.desktopEnv == "hyprland") {
      nixconf.graphical.wayland = {
        enable = true;
        hyprland.enable = true;
      };
    })

  ]);
}
