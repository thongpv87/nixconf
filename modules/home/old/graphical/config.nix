{ pkgs, config, lib, ... }:
with lib; {
  config.nixconf.old.graphical = {
    enable = mkDefault false;

    wayland = {
      enable = mkDefault false;
      type = mkDefault null;

      background = {
        enable = mkDefault true;
        path = "/home/thongpv87/Pictures/Wallpapers";
      };

      statusbar = { enable = mkDefault false; };

      screenlock = { enable = mkDefault false; };
    };
  };
}
