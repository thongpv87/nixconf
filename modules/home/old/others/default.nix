{ pkgs, config, lib, ... }:
with lib;
let cfg = config.nixconf.old.others;
in {
  imports = [
    # ./develop
    ./media
    ./others
  ];

  options.nixconf.old.others.enable = mkOption {
    type = types.bool;
    default = false;
  };

  config = mkIf cfg.enable {
    nixconf.old.others = {
      # develop.haskell.enable = mkDefault true;
      # develop.agda.enable = mkDefault true;
      others.enable = mkDefault true;
      #mime.enable = mkDefault false;
      media.glava.enable = mkDefault true;
    };
  };
}
