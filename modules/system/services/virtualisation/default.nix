{
  pkgs,
  config,
  lib,
  modulesPath,
  ...
}:
let
  cfg = config.nixconf.services.virtualisation;
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
  fake-docker-compose = pkgs.writeScriptBin "docker-compose" ''
    ${pkgs.podman-compose}/bin/podman-compose $@
  '';

in
{
  options.nixconf.services.virtualisation = {
    enable = mkOption { default = false; };

    enablePodman = mkEnableOption "Enable podman/docker";

    enableVirtualBox = mkEnableOption "Enable virtualbox";
  };

  config = lib.mkIf cfg.enable (mkMerge [
    (mkIf cfg.enablePodman {
      environment.systemPackages = with pkgs; [ podman-compose fake-docker-compose postman ];
      virtualisation = {
        podman = {
          enable = true;

          # Create a `docker` alias for podman, to use it as a drop-in replacement
          dockerCompat = true;

          # Required for containers under podman-compose to be able to talk to each other.
          defaultNetwork.settings.dns_enabled = true;
        };
      };
    })

    (mkIf cfg.enableVirtualBox {
      virtualisation.virtualbox = { host.enable = true; };
      users.extraGroups.vboxusers.members = [ "thongpv87" ];
    })
  ]);
}
