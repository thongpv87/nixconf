{
  pkgs,
  config,
  lib,
  modulesPath,
  ...
}:
let
  cfg = config.nixconf.networking;
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
  options.nixconf.networking = {
    enable = mkOption { default = false; };
  };

  imports = [
    ./cloudflare-warp
    ./encrypted-dns
  ];

  config = lib.mkIf cfg.enable {
    networking = {
      wireless.iwd = {
        enable = true;
        settings = {
          Settings = {
            AutoConnect = true;
          };
        };
      };
      networkmanager = {
        enable = true;
        wifi = {
          powersave = true;
          backend = mkForce "iwd";
        };

        settings = {
          device = {
            "wifi.scan-rand-mac-address" = "no";
          };
        };
      };
    };
  };
}
