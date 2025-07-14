{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.nixconf.services.display-manager;
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
  options.nixconf.services.display-manager = {
    enable = mkEnableOption "Enable display manager";
    window-manager = mkOption { type = types.enum [ "hyprland" ]; };
  };

  imports = [ ./hyprland ];

  config = mkIf cfg.enable (mkMerge [
    (mkIf (cfg.window-manager == "hyprland") {
      nixconf.services.display-manager = {
        hyprland = {
          enable = true;

          window = "default";
          decoration = "rounding";
          animation = "fast";

          quickshell.enable = true;
        };
      };
    })

  ]);
}
