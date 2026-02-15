{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.nixconf.adhoc;
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
  options.nixconf.adhoc = {
    enable = mkEnableOption "Enable adhoc configs";
  };

  config = mkIf cfg.enable (mkMerge [
    {
      environment.systemPackages = [
        pkgs.minicom
        pkgs.freecad
        pkgs.picocom
        pkgs.obsidian
        pkgs.socat
        pkgs.screen
        pkgs.code-cursor
        pkgs.claude-code
      ];
    }
    {
      services.tailscale = {
        enable = true;
        useRoutingFeatures = "client";
      };
    }
    {
      environment.systemPackages = [
        (pkgs.wineWowPackages.stable.override { waylandSupport = true; })
        pkgs.lutris
      ];
    }
    # adhoc
    {
      environment.systemPackages = [
        pkgs.python3
        pkgs.elixir
        pkgs.gtk4
        pkgs.appimage-run

        pkgs.shellcheck
        pkgs.nodePackages.bash-language-server
        pkgs.sweethome3d.application

        pkgs.discord
        pkgs.slack
        pkgs.ngrok
        #pkgs.dbeaver-bin
        pkgs.antares
      ];

    }
    {
      nix.settings = {
        trusted-substituters = [
          "https://nixcache.reflex-frp.org"
          "https://nix-node.cachix.org"
        ];
        trusted-public-keys = [
          "ryantrinkle.com-1:JJiAKaRv9mWgpVAz8dwewnZe0AzzEAzPkagE9SP5NWI="
          "nix-node.cachix.org-1:2YOHGtGxa8VrFiWAkYnYlcoQ0sSu+AqCniSfNagzm60="
        ];
      };

      nix.registry."node".to = {
        type = "github";
        owner = "andyrichardson";
        repo = "nix-node";
      };
    }
  ]);
}
