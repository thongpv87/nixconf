{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.nixconf.graphical.xorg.xmonad;
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
  options.nixconf.graphical.xorg.xmonad = {
    enable = mkEnableOption "Enable xorg desktop server";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      alacritty
      acpi
      playerctl
      jq
      xclip
      brightnessctl
      imagemagick
      elisa
      gwenview
      kdePackages.okular
      konversation

      # xmonad pkgs
      jq
      xclip
      feh
      rofi
      brightnessctl
      xorg.xbacklight
      xorg.setxkbmap
      font-awesome
      selected-nerdfonts
    ];

    services.xserver = {
      displayManager.gdm.enable = true;
      windowManager.xmonad = {
        enable = true;
        enableContribAndExtras = true;
      };
    };
  };
}
