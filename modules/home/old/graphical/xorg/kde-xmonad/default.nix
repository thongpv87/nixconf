{ pkgs, config, lib, ... }:
with lib;
let
  cfg = config.nixconf.old.graphical.xorg.kde-xmonad;
  systemCfg = config.machineData.systemConfig;
in {
  options.nixconf.old.graphical.xorg.kde-xmonad = {
    enable = mkOption {
      description = "Enable kde-xmonad";
      type = types.bool;
      default = false;
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = systemCfg.graphical.desktop-env.kde.enable;
        message = "To enable xmonad for user, it must be enabled for system";
      }

      {
        assertion = systemCfg.graphical.xorg.enable;
        message = "To enable xorg for user, it must be enabled for system";
      }
    ];

    systemd.user.services.xmonad = {
      Install = { WantedBy = [ "plasma-workspace.target" ]; };

      Unit = {
        Description = "Plasma Custom Window Manager";
        Before = [ "plasma-workspace.target" ];
      };

      Service = {
        ExecStart = "/run/current-system/sw/bin/xmonad";
        Restart = "on-failure";
        Slice = "session.slice";
      };
    };
  };
}
