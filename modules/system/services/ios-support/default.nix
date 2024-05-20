{
  pkgs,
  config,
  lib,
  modulesPath,
  ...
}:
let
  cfg = config.nixconf.services.ios-support;
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
  options.nixconf.services.ios-support = {
    enable = mkOption { default = false; };
  };

  config = lib.mkIf cfg.enable {
    # services.usbmuxd = {
    #   enable = true;
    #   package = pkgs.usbmuxd2;
    # };

    environment.systemPackages = with pkgs; [
      pkgs.libimobiledevice
      pkgs.ifuse
    ];
  };
}
