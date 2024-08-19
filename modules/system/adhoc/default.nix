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

  keet =
    let
      pname = "Keet";
      version = "latest";

      src = pkgs.fetchurl {
        url = "https://keet.io/downloads/${version}/Keet-x64.tar.gz";
        sha256 = "sha256-Z0/Ft+vK2lKsqz1rKdy7e9OCopq4b8cRLIhmTFfoSCI=";
        postFetch = ''
          cp $out src.tar.gz
          ${pkgs.gnutar}/bin/tar -xzf src.tar.gz -O > $out
        '';
      };

      appimageContents = pkgs.appimageTools.extract { inherit pname version src; };
    in
    pkgs.appimageTools.wrapType2 {
      inherit src pname version;

      extraInstallCommands = ''
        install -m 444 -D ${appimageContents}/${pname}.desktop -t $out/share/applications
        substituteInPlace $out/share/applications/${pname}.desktop \
          --replace 'Exec=AppRun' 'Exec=${pname}'
      '';

      meta = with lib; {
        description = "Peer-to-Peer Chat";
        homepage = "https://keet.io";
        license = licenses.unfree;
        maintainers = with maintainers; [ extends ];
        platforms = [ "x86_64-linux" ];
      };
    };
in
{
  options.nixconf.adhoc = {
    enable = mkEnableOption "Enable adhoc configs";
  };

  config = mkIf cfg.enable (mkMerge [
    {
      services.tailscale = {
        enable = false;
        useRoutingFeatures = "client";
      };
      #networking.firewall.enable = false;
    }

    # adhoc
    {
      environment.systemPackages = [
        pkgs.python3
        pkgs.elixir_1_15
        keet
        pkgs.gtk4
        pkgs.appimage-run

        pkgs.shellcheck
        pkgs.nodePackages.bash-language-server
        pkgs.sweethome3d.application

        pkgs.slack
        pkgs.ngrok
        pkgs.dbeaver-bin
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
