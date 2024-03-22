{ config, pkgs, lib, ... }:
with lib;
let
  cfg = config.nixconf.services.display-manager.swayidle;
  inherit (lib)
    mkOption mkMerge mkIf mkDefault mkForce types mdDoc mkEnableOption;
in {
  options.nixconf.services.display-manager.swayidle = {
    enable = mkOption { default = false; };
  };
  config = mkIf cfg.enable {
    services.swayidle = {
      enable = true;
      events = [{
        event = "before-sleep";
        command = "${pkgs.swaylock}/bin/swaylock";
      }];
      timeouts = [
        {
          timeout = 600;
          command = "${pkgs.hyprland}/bin/hyprctl dispatch dpms off";
        }
        {
          timeout = 1200;
          command = "${pkgs.swaylock}/bin/swaylock";
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
