{
  config,
  pkgs,
  lib,
  ...
}:
with lib;
let
  cfg = config.nixconf.services.display-manager.hyprland.quickshell;
  inherit (lib)
    mkOption
    mkMerge
    mkIf
    mkDefault
    mkForce
    types
    mdDoc
    mkEnableOption
    ;

in
{
  imports = [
    ./config.nix
    ./packages.nix
  ];

  options.nixconf.services.display-manager.hyprland.quickshell = {
    enable = mkEnableOption "Enable quickshell";
  };

  config = mkIf cfg.enable {
    # xdg.configFile."quickshell/caelestia" = {
    #   source = ./qs2;
    #   recursive = true;
    # };
    #
    home.packages = with pkgs; [
      # Qt dependencies
      qt6.qt5compat
      qt6.qtdeclarative

      # Runtime dependencies
      hyprpaper
      imagemagick
      wl-clipboard
      fuzzel
      socat
      foot
      jq
      python3
      python3Packages.materialyoucolor
      grim
      wayfreeze
      wl-screenrec
      pkgs.astal.io
      #astal.default
      #inputs.astal.packages.${pkgs.system}.default

      # Additional dependencies
      lm_sensors
      curl
      material-symbols
      nerd-fonts.jetbrains-mono
      ibm-plex
      fd
      python3Packages.pyaudio
      python3Packages.numpy
      cava
      networkmanager
      bluez
      ddcutil
      brightnessctl
      fish

      # Wrapper for caelestia to work with quickshell
      (writeScriptBin "caelestia-quickshell" ''
        #!${pkgs.fish}/bin/fish

        # Override for caelestia shell commands to work with quickshell
        set -l original_caelestia ${config.programs.quickshell.caelestia-scripts}/bin/caelestia

        if test "$argv[1]" = "shell" -a -n "$argv[2]"
            set -l cmd $argv[2]
            set -l args $argv[3..]
            
            switch $cmd
                case "show" "toggle"
                    if test -n "$args[1]"
                        exec ${config.programs.quickshell.finalPackage}/bin/qs -c caelestia ipc call drawers $cmd $args[1]
                    else
                        echo "Usage: caelestia shell $cmd <drawer>"
                        exit 1
                    end
                case "media"
                    if test -n "$args[1]"
                        set -l action $args[1]
                        switch $action
                            case "play-pause"
                                exec ${config.programs.quickshell.finalPackage}/bin/qs -c caelestia ipc call mpris playPause
                            case '*'
                                exec ${config.programs.quickshell.finalPackage}/bin/qs -c caelestia ipc call mpris $action
                        end
                    else
                        echo "Usage: caelestia shell media <action>"
                        exit 1
                    end
                case '*'
                    # For other shell commands, try the original
                    exec $original_caelestia $argv
            end
        else
            # For non-shell commands, use the original
            exec $original_caelestia $argv
        end
      '')
    ];

    # Systemd service
    systemd.user.services.caelestia-shell = {
      Unit = {
        Description = "Caelestia desktop shell";
        After = [ "graphical-session.target" ];
      };
      Service = {
        Type = "exec";
        ExecStart = "${config.programs.quickshell.finalPackage}/bin/qs -c caelestia";
        Restart = "on-failure";
        Slice = "app-graphical.slice";
      };
      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };

    # Shell aliases
    home.shellAliases = {
      caelestia-shell = "qs -c caelestia";
      caelestia = "caelestia-quickshell";
    };

  };

}
