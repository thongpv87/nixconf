{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.nixconf.graphical;
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

  initial_session_config = pkgs.writeText "hyprland-initial-session.conf" ''
    exec-once = ${lib.getExe config.programs.regreet.package}; hyprctl dispatch exit
  '';
in
{
  imports = [
    ./xorg
    ./wayland
  ];
  options.nixconf.graphical = {
    enable = mkEnableOption "Enable graphical desktop environment";
    desktopEnv = mkOption {
      type = types.enum [
        "xmonad"
        "hyprland"
      ];
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      services.displayManager.sddm = {
        enable = true;
        wayland.enable = true;
      };


      hardware = {
        opengl = {
          enable = true;
          driSupport32Bit = true;
          extraPackages = with pkgs; [
            rocm-opencl-icd
            rocm-opencl-runtime
            amdvlk
            libva
          ];
        };
      };
    }
    (mkIf (cfg.desktopEnv == "xmonad") {
      nixconf.graphical.xorg = {
        enable = true;
        xmonad.enable = true;
      };
    })
    (mkIf (cfg.desktopEnv == "hyprland") {
      nixconf.graphical.wayland = {
        enable = true;
        hyprland.enable = true;
      };
    })
  ]);
}
