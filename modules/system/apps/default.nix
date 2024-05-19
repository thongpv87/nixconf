{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.nixconf.apps;
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
  imports = [ ];
  options.nixconf.apps = {
    enable = mkEnableOption "Enable system apps";
  };

  config = mkIf cfg.enable (mkMerge [
    {
      programs = {
        dconf.enable = true;
        iftop.enable = true;
        iotop.enable = true;
        zsh.enable = true;
      };

      environment = {
        systemPackages = with pkgs; [
          #utilities packages
          firefox
          chromium
          ghc
          nixfmt-rfc-style
          config.boot.kernelPackages.bcc

          taskwarrior
          timewarrior
          taskwarrior-tui
        ];
        pathsToLink = [ "/share/zsh" ];
      };
    }
  ]);
}
