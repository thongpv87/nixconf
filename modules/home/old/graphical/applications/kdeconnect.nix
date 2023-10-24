{ pkgs, config, lib, ... }:
with lib;
let
  cfg = config.nixconf.old.graphical.applications;
  isGraphical = let cfg = config.nixconf.old.graphical;
  in (cfg.xorg.enable == true || cfg.wayland.enable == true);

  portsOpen = let cfg = config.machineData.systemConfig.networking.firewall;
  in (!cfg.enable || cfg.allowKdeconnect);
in {
  options.nixconf.old.graphical.applications.kdeconnect = {
    enable = mkOption {
      default = false;
      type = types.bool;
      description = "Enable libreoffice with config [libreoffice]";
    };
  };

  config = mkIf (isGraphical && cfg.enable && cfg.kdeconnect.enable
    && (assertMsg portsOpen "need to open ports on host")) {
      services.kdeconnect = {
        enable = true;
        indicator = true;
      };
    };
}
