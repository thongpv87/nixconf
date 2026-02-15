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
      services.displayManager.gdm = {
        wayland = true;
        enable = true;
      };

      hardware = {
        graphics = {
          enable = true;
          extraPackages = with pkgs; [
            rocmPackages.clr.icd
            rocmPackages.rocm-runtime
            libva
          ];
          enable32Bit = true;
        };

        amdgpu = {
          opencl.enable = true;
          initrd.enable = true;
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
