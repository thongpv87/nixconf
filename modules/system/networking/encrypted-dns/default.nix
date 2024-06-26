{
  pkgs,
  config,
  lib,
  modulesPath,
  ...
}:
let
  cfg = config.nixconf.networking.encrypted-dns;
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
  options.nixconf.networking.encrypted-dns = {
    enable = mkOption { default = false; };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = !config.services.resolved.enable;
        message = "services.resolved.enable can not use a long with encrypted dns config";
      }
    ];

    networking = {
      nameservers = [
        "127.0.0.1"
        "::1"
      ];
      # If using dhcpcd:
      dhcpcd.extraConfig = "nohook resolv.conf";
      # If using NetworkManager:
      networkmanager.dns = "none";
    };

    services.dnscrypt-proxy2 = {
      enable = true;
      settings = {
        ipv6_servers = true;
        require_dnssec = true;

        dnscrypt_servers = true;
        doh_servers = true;
        ignore_system_dns = true;

        sources.public-resolvers = {
          urls = [
            "https://raw.githubusercontent.com/DNSCrypt/dnscrypt-resolvers/master/v3/public-resolvers.md"
            "https://download.dnscrypt.info/resolvers-list/v3/public-resolvers.md"
          ];
          cache_file = "/var/lib/dnscrypt-proxy2/public-resolvers.md";
          minisign_key = "RWQf6LRCGA9i53mlYecO4IzT51TGPpvWucNSCh1CBM0QTaLn73Y7GFO3";
        };

        sources.quad9-resolvers = {
          urls = ["https://www.quad9.net/quad9-resolvers.md"];
          minisign_key = "RWQBphd2+f6eiAqBsvDZEBXBGHQBJfeG6G+wJPPKxCZMoEQYpmoysKUN";
          cache_file = "quad9-resolvers.md";
          prefix = "quad9-";
        };

        # You can choose a specific set of servers from https://github.com/DNSCrypt/dnscrypt-resolvers/blob/master/v3/public-resolvers.md
        # server_names = [ ... ];
      };
    };

    systemd.services.dnscrypt-proxy2.serviceConfig = {
      StateDirectory = "dnscrypt-proxy";
    };
  };
}
