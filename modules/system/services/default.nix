{
  pkgs,
  config,
  lib,
  modulesPath,
  ...
}:
let
  cfg = config.nixconf.services;
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
  options.nixconf.services = {
    enable = mkOption { default = false; };
  };

  imports = [ ./ios-support ./virtualisation ];

  config = lib.mkIf cfg.enable {
  };
}
