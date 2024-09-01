{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.nixconf.core.nix-ld;
  inherit (lib)
    mkOption
    mkMerge
    mkIf
    mkDefault
    mkForce
    types
    ;
in
{
  options.nixconf.core.nix-ld = {
    enable = mkOption {
      default = true;
      description = "Enable core system config";
    };
  };

  config = mkIf cfg.enable {
    programs.nix-ld = {
      enable = true;
      libraries = with pkgs; [
        # Add any missing dynamic libraries for unpackaged programs here, NOT in environment.systemPackages
        lua-language-server
        zlib
        zlib.dev
      ];
    };
  };
}
