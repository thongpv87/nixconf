{
  pkgs,
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.nixconf.terminal.nushell;
  mnet = pkgs.nushellPlugins.net.overrideAttrs (oldAttrs: rec {
    src = oldAttrs.src.overrideAttrs (oldSrcAttrs: {
      sha256 = "sha256-bsrpdQS0wA3T0jZTG476sSkMRngEAOjgr4wX7svyMP4=";
    });
  });
in
{
  options.nixconf.terminal.nushell = {
    enable = mkOption {
      description = "Enable nushell with settings";
      type = types.bool;
      default = false;
    };
  };

  config = mkIf (cfg.enable) (
    let
    in
    {
      home.packages = with pkgs.nushellPlugins; [
        #mnet
      ];

      programs = {
        starship.enableNushellIntegration = true;
        direnv.enableNushellIntegration = true;
        thefuck.enableNushellIntegration = true;
        atuin.enableNushellIntegration = true;

        yazi = {
          enable = true;
          enableNushellIntegration = true;
        };

        carapace = {
          enable = true;
          enableNushellIntegration = true;
        };

        nushell = {
          enable = true;
          # configFile.source = ./_config.nu;
          envFile.source = ./_env.nu;
          extraConfig = "${lib.readFile ./_extra_config.nu}";
        };
      };
    }
  );
}
