{ pkgs, config, lib, ... }:
with lib;
let
  cfg = config.nixconf.old.graphical;
  systemCfg = config.machineData.systemConfig;
in {
  options.nixconf.old.graphical.applications = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable graphical applications";
    };
  };

  config = mkIf (cfg.applications.enable) {
    home.packages = with pkgs; [
      okular
      xorg.xinput

      microsoft-edge

      # updated version with wayland/grim backend
      libsixel

      # Password manager
      bitwarden

      # Reading
      calibre

      # Video conference
      zoom-us

      # Note taking
      xournalpp
      rnote

      # Sound
      pavucontrol
      pasystray

      # music
      rhythmbox

      # kdeconnect
    ];
  };
}
