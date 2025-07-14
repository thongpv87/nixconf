{
  config,
  pkgs,
  lib,
  ...
}:
with lib;
let
  cfg = config.nixconf.services.display-manager.hyprland.quickshell;
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
  options.nixconf.services.display-manager.hyprland.quickshell = {
    enable = mkEnableOption "Enable quickshell";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      quickshell
      material-symbols
    ];

    xdg.configFile."quickshell/caelestia" = {
      source = ./caelestia;
      recursive = true;
    };
  };

}
