{ pkgs, config, lib, modulesPath, ... }:
let
  cfg = config.nixconf.laptop;
  inherit (lib)
    mkOption mkMerge mkIf mkDefault mkForce types mdDoc mkEnableOption;
in {
  options.nixconf.laptop = {
    enable = mkOption { default = false; };
    tlp = mkOption {

    };
  };

  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  config = lib.mkIf cfg.enable { };
}
