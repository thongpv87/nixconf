{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.nixconf.services.ai;
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
  options.nixconf.services.ai = {
    enable = mkEnableOption "Enable display manager";
    window-manager = mkOption { type = types.enum [ "hyprland" ]; };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      home.packages = with pkgs; [
        claude-code
        google-gemini
        opencode
        opencode-claude-auth
        opencode-desktop
      ];
    }
  ]);
}
