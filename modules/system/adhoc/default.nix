{ config, pkgs, lib, ... }:
let
  cfg = config.nixconf.adhoc;
  inherit (lib)
    mkOption mkMerge mkIf mkDefault mkForce types mdDoc mkEnableOption;

in {
  options.nixconf.adhoc = { enable = mkEnableOption "Enable adhoc configs"; };

  config = mkIf cfg.enable (mkMerge [
    {
      services.tailscale = {
        enable = true;
        useRoutingFeatures = "client";
      };
      networking.firewall.enable = false;
    }

    # adhoc
    {
      environment.systemPackages = [
        pkgs.python3
        pkgs.elixir_1_15

        pkgs.shellcheck
        pkgs.nodePackages.bash-language-server

        pkgs.zoom-us
        pkgs.slack
        pkgs.ngrok
        pkgs.dbeaver
        pkgs.teams-for-linux
        pkgs.dia
      ];

      services.postgresql = {
        enable = true;
        extraPlugins = with pkgs.postgresql.pkgs; [ timescaledb ];
        authentication = pkgs.lib.mkOverride 10 ''
          #type database  DBuser  auth-method
          local all       all     trust
          host  all       all     127.0.0.1       255.255.255.255     trust
        '';
        settings = {
          shared_preload_libraries = "timescaledb";
          log_statement = "all";
        };
      };
    }

    {
      nix.settings= {
        trusted-substituters = [ "https://nixcache.reflex-frp.org" "https://nix-node.cachix.org" ];
        trusted-public-keys = [ "ryantrinkle.com-1:JJiAKaRv9mWgpVAz8dwewnZe0AzzEAzPkagE9SP5NWI=" "nix-node.cachix.org-1:2YOHGtGxa8VrFiWAkYnYlcoQ0sSu+AqCniSfNagzm60=" ];
      };

      nix.registry."node".to = {
        type = "github";
        owner = "andyrichardson";
        repo = "nix-node";
      };

    }
  ]);
}
