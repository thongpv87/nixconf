{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.nixconf.core.ssh;
in
{
  options.nixconf.core.ssh = {
    enable = mkOption {
      description = "Enable ssh";
      type = types.bool;
      default = false;
    };
  };

  config = mkIf cfg.enable {
    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      matchBlocks = {
        "*" = {
          addKeysToAgent = "yes";
          extraOptions = {
            ControlMaster = "auto";
            ControlPersist = "10d";
          };
        };
        localhost = {
          hostname = "127.0.0.1";
          user = "root";
          identityFile = "~/.ssh/local";
        };
      };
    };
  };
}
