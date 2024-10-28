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
    if [ $(ibus engine) == xkb:us::eng ]; then ibus engine Bamboo; else ibus engine xkb:us::eng ; fi
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
