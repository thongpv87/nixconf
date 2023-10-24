{ pkgs, config, lib, ... }:
with lib;
let cfg = config.nixconf.old.ssh;
in {
  options.nixconf.old.ssh = {
    enable = mkOption {
      description = "enable ssh";
      type = types.bool;
      default = false;
    };
  };

  config = mkIf cfg.enable {
    programs.ssh = {
      enable = true;
      matchBlocks = {
        localhost = {
          hostname = "127.0.0.1";
          user = "root";
          identityFile = "~/.ssh/local";
        };
        "38.45.64.210" = { forwardAgent = true; };
      };
      extraConfig = ''
        AddKeysToAgent yes
      '';
    };
  };
}
