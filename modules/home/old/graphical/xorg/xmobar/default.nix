{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.nixconf.old.graphical.xorg.xmobar;

  main-statusbar = pkgs.writeShellScriptBin "main-statusbar" ''
    ${pkgs.xmobar}/bin/xmobar /home/thongpv87/.xmonad/xmobar/doom-one-xmobarrc
  '';
in {
  options.nixconf.old.graphical.xorg.xmobar = {
    enable = mkOption { default = false; };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [ xmobar main-statusbar ];

    home.file = {
      ".xmonad/xmobar" = {
        source = ./xmobar;
        recursive = true;
      };
    };
  };
}
