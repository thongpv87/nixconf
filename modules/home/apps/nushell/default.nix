{ pkgs, config, lib, ... }:
with lib;
let cfg = config.nixconf.apps.nushell;
in {
  options.nixconf.apps.nushell = {
    enable = mkOption {
      description = "Enable nushell with settings";
      type = types.bool;
      default = false;
    };
  };

  config = mkIf (cfg.enable) (let
  in {
    home.packages = with pkgs.nushellPlugins; [ net ];

    programs = {
      fish.enable = true;

      starship = {
        enable = true;
        enableNushellIntegration = true;
      };

      direnv = {
        enable = true;
        enableNushellIntegration = true;
      };
      thefuck = {
        enable = true;
        enableNushellIntegration = true;
      };
      yazi = {
        enable = true;
        enableNushellIntegration = true;
      };

      atuin = {
        enable = true;
        enableNushellIntegration = true;
      };

      carapace = {
        enable = true;
        enableNushellIntegration = true;
      };


      nushell = {
        enable = true;
        package = pkgs.nushellFull;
        # configFile.source = ./_config.nu;
        # envFile.source = ./_env.nu;
        extraConfig = "${lib.readFile ./_extra_config.nu}";
        extraEnv = ''
          $env.PROMPT_INDICATOR = "〉"
          $env.PROMPT_INDICATOR_VI_INSERT = "〉 "
          $env.PROMPT_INDICATOR_VI_NORMAL = " "
          $env.PROMPT_MULTILINE_INDICATOR = "::: "
        '';
      };
    };
  });
}
