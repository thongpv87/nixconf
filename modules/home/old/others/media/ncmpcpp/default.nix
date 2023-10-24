{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.nixconf.old.others.media.ncmpcpp;
  music-hub = pkgs.writeShellScriptBin "music-hub" ''
    systemctl --user start mopidy
    exec alacritty --class music-hub --title ncmpcpp -e ncmpcpp $@
  '';
in {
  options.nixconf.old.others.media.ncmpcpp.enable =
    mkOption { default = false; };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [ ncmpcpp music-hub ];

    xdg.configFile."ncmpcpp" = {
      source = ./config/mechanical_love;
      recursive = true;
    };
  };
}
