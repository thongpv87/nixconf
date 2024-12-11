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
        pkgs.picocom
        pkgs.socat
        pkgs.screen
      ];
    }
    {
      services.tailscale = {
        enable = true;
        useRoutingFeatures = "client";
      };
      #networking.firewall.enable = false;
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
        pkgs.elixir_1_15
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

      services.postgresql = {
        enable = false;
        extensions = with pkgs.postgresql.pkgs; [ timescaledb ];
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
      environment.sessionVariables = {
        GTK_IM_MODULE = "fcitx";
        QT_IM_MODULE = "fcitx";
        XMODIFIERS = "@im=fcitx";
        SDL_IM_MODULE = "fcitx";
        GLFW_IM_MODULE = "fcitx";
        QT_IM_MODULES = "wayland;fcitx;ibus";
      };
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
