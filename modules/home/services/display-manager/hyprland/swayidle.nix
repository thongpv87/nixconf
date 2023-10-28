{ config, pkgs, lib, ... }:
with lib;
let
  cfg = config.nixconf.services.display-manager.swayidle;
  inherit (lib)
    mkOption mkMerge mkIf mkDefault mkForce types mdDoc mkEnableOption;
in {
  options.nixconf.services.display-manager.swayidle = {
    enable = mkOption { default = true; };
  };
  config = mkIf cfg.enable {
    services.swayidle = {
      enable = true;
      events = [{
        event = "before-sleep";
        command = "${pkgs.waylock}/bin/swaylock --fork-on-lock";
      }];
      timeouts = [
        {
          timeout = 600;
          command = "${pkgs.hyprland}/bin/hyprctl dispatch dpms off";
        }
        {
          timeout = 1200;
          command = "${pkgs.waylock}/bin/waylock --fork-on-lock";
        }
        {
          timeout = 1200;
          command = "${pkgs.systemd}/bin/systemctl suspend-then-hibernate";
          resumeCommand = "${pkgs.hyprland}/bin/hyprctl dispatch dpms on";
        }
      ];
    };
  };
}
