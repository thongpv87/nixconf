{ config, lib, pkgs, ... }:

with lib;
let cfg = config.nixconf.old.others.media;
in {
  imports = [
    #./cli-visualizer
    ./mopidy
    ./ncmpcpp
    ./glava
  ];

  options.nixconf.old.others.media = {
    enable = mkOption {
      default = false;
      description = ''
        Whether to enable xmonad bundle
      '';
    };
  };

  config = mkIf cfg.enable (mkMerge [{
    home.packages = with pkgs; [ rhythmbox vlc shotwell pavucontrol ];

    nixconf.old.others.media = {
      mopidy.enable = true;
      ncmpcpp.enable = true;
      glava.enable = true;

    };
  }]);
}
