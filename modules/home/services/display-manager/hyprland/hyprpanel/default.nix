{
  config,
  pkgs,
  lib,
  ...
}:
with lib;
let
  cfg = config.nixconf.services.display-manager.hyprland.hyprpanel;
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

  switch-input-method = pkgs.writeShellScriptBin "switch-input-method" ''
    current=$(${pkgs.fcitx5}/bin/fcitx5-remote -n 2>/dev/null)
    if [ "$current" = "unikey" ]; then
      ${pkgs.fcitx5}/bin/fcitx5-remote -s keyboard-us
    else
      ${pkgs.fcitx5}/bin/fcitx5-remote -s unikey
    fi
  '';
  screenshot-region = pkgs.writeShellScriptBin "screenshot-region" ''
    ${pkgs.grim}/bin/grim -g "$(${pkgs.slurp}/bin/slurp)"
  '';

in
{
  options.nixconf.services.display-manager.hyprland.hyprpanel = {
    enable = mkEnableOption "Enable Hyprpanel";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      hyprpanel
    ];

    systemd.user.services = {
      hyprpanel = {
        Unit = {
          Description = "Hyprpanel";
          After = [ "hm-graphical-session.target" ];
          PartOf = [ "graphical-session.target" ];
        };
        Service = {
          ExecStart = "${pkgs.hyprpanel}/bin/hyprpanel";
        };
        Install = {
          WantedBy = [ "graphical-session.target" ];
        };
      };
    };

  };

}
