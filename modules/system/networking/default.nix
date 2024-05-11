{ pkgs, config, lib, modulesPath, ... }:
let
  cfg = config.nixconf.networking;
  inherit (lib)
    mkOption mkMerge mkIf mkDefault mkForce types mdDoc mkEnableOption;
in {
  options.nixconf.networking= {
    enable = mkOption { default = false; };
    tlp = mkOption {

    };
  };

  imports = [ ./cloudflare-warp ];

  config = lib.mkIf cfg.enable { };
}
