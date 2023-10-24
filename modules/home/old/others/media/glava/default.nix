{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.nixconf.old.others.media.glava;
  glava-graph-3840 = pkgs.writeShellScriptBin "glava-graph-3840" ''
    exec ${pkgs.glava}/bin/glava $@ -m graph -r 'setgeometry 0 1855 3840 300' -r 'setxwintype "desktop"'
  '';
  glava-radial-3840 = pkgs.writeShellScriptBin "glava-radial-3840" ''
    exec ${pkgs.glava}/bin/glava $@ -m radial -r 'setgeometry 1560 600 600 600' -r 'setxwintype "!-"'
  '';
in {
  options.nixconf.old.others.media.glava = {
    enable = mkOption { default = false; };
  };

  config = mkIf cfg.enable (mkMerge [{
    home.packages = with pkgs; [ glava glava-graph-3840 glava-radial-3840 ];

    # xdg.configFile."glava" = {
    #   source = ./glava;
    #   recursive = true;
    # };
  }]);
}
