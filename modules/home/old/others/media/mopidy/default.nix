{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.nixconf.old.others.media.mopidy;
  mopidyEnv = with pkgs;
    buildEnv {
      name = "mopidy-with-extensions-${mopidy.version}";
      paths = closePropagation [
        mopidy-youtube
        mopidy-mpris
        mopidy-mpd
        mopidy-local
      ];
      pathsToLink = [ "/${mopidyPackages.python.sitePackages}" ];
      buildInputs = [ makeWrapper ];
      postBuild = ''
        makeWrapper ${mopidy}/bin/mopidy $out/bin/mopidy \
          --prefix PYTHONPATH : $out/${mopidyPackages.python.sitePackages}
      '';
    };
in {
  options.nixconf.old.others.media.mopidy.enable =
    mkOption { default = false; };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [ mopidyEnv mpc_cli cli-visualizer ];

    xdg.configFile."mopidy/mopidy.conf.in".source = ./mopidy.conf;

    home.activation = {
      mopidyActivation = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        $DRY_RUN_CMD cp $HOME/.config/mopidy/mopidy.conf.in $HOME/.config/mopidy/mopidy.conf
        chmod 600 $HOME/.config/mopidy/mopidy.conf
      '';
    };

    systemd.user.services = {
      mopidy = {
        Unit = {
          Description = "Mopidy music server";
          After = [ "network.target" "sound.target" ];

        };

        Service = {
          ExecStart = "${mopidyEnv}/bin/mopidy";
          Restart = "on-failure";
          RestartSec = 3;
        };

        Install.WantedBy = [ "multi-user.target" ];
      };
    };
  };
}
