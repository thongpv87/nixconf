{ config, pkgs, lib, ... }:
let
  cfg = config.nixconf.services.display-manager;
  inherit (lib)
    mkOption mkMerge mkIf mkDefault mkForce types mdDoc mkEnableOption;
in {
  options.nixconf.services.display-manager = {
    enable = mkEnableOption "Enable display manager";
    window-manager = mkOption { type = types.enum [ "hyprland" "hypr" ]; };
  };

  imports = [ ./hyprland ./hypr ];

  config = mkIf cfg.enable (mkMerge [
    (mkIf (cfg.window-manager == "hyprland") {
      nixconf.services.display-manager = {
        hyprland.enable = true;
        swayidle.enable = false;
      };
    })

    (mkIf (cfg.window-manager == "hypr") {
      nixconf.services.display-manager = {
        hypr = {
          enable = true;

          window = "no-border";
          decoration = "rounding-more-blur";
          animation = "moving";
        };
        swayidle.enable = false;
      };
    })

  ]);
}
