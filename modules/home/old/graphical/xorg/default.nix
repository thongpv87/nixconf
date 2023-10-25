{ pkgs, config, lib, ... }:
with lib;
let
  cfg = config.nixconf.old.graphical.xorg;
  systemCfg = config.machineData.systemConfig;
in {
  imports = [ ./xmonad ./kde-xmonad ];

  options.nixconf.old.graphical.xorg = {
    enable = mkOption {
      description = "Enable xorg";
      type = types.bool;
      default = false;
    };

    screenlock = {
      enable = mkOption {
        description = "Enable screen locking (xss-lock). Only used with dwm";
        type = types.bool;
        default = false;
      };

      timeout = {
        script = mkOption {
          description = "Script to run on timeout. Default null";
          type = with types; nullOr package;
          default = null;
        };

        time = mkOption {
          description =
            "Time in seconds until run timeout script. Default 180.";
          type = types.int;
          default = 180;
        };
      };

      lock = {
        command = mkOption {
          description = "Lock command. Default xsecurelock";
          type = types.str;
          default = "${pkgs.xsecurelock}/bin/xsecurelock";
        };

        time = mkOption {
          description =
            "Time in seconds after timeout until lock. Default 180.";
          type = types.int;
          default = 180;
        };
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    { xsession = { enable = true; }; }

    {
      systemd.user.services = mkIf (cfg.screenlock.enable) {
        xss-lock = {
          Install = { WantedBy = [ "xmonad-session.target" ]; };

          Unit = {
            Description = "XSS Lock Daemon";
            # PartOf = [ "" ];
            After = [ "graphical-session.target" ];
          };

          Service = {
            ExecStart = "${pkgs.xss-lock}/bin/xss-lock -s \${XDG_SESSION_ID} ${
                if cfg.screenlock.timeout.script == null then
                  ""
                else
                  "-n ${cfg.screenlock.timeout.script}"
              } -l -- ${cfg.screenlock.lock.command}";
          };
        };
      };
    }

  ]);
}
