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
        appimage.binfmt = true;
      };

      environment = {
        systemPackages = with pkgs; [
          #utilities packages
          firefox
          chromium
          google-chrome
          ghc
          nixfmt
          config.boot.kernelPackages.bcc

          taskwarrior3
          timewarrior
          taskwarrior-tui
        ];
        pathsToLink = [ "/share/zsh" ];
      };
    }
  ]);
}
