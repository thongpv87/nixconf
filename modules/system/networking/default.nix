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
          General = {
            EnableNetworkConfiguration = false;
          };
        };
      };
      networkmanager = {
        enable = true;
        wifi = {
          powersave = false;
          backend = mkForce "iwd";
        };

        settings = {
          device = {
            "wifi.scan-rand-mac-address" = "no";
          };
        };
      };
    };

    # Restart NetworkManager after suspend to fix WiFi reconnection (especially 5GHz)
    powerManagement.resumeCommands = ''
      ${pkgs.networkmanager}/bin/nmcli radio wifi off || true
      ${pkgs.coreutils}/bin/sleep 2
      ${pkgs.networkmanager}/bin/nmcli radio wifi on || true
    '';
  };
}
