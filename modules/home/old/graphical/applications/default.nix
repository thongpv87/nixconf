{ pkgs, config, lib, ... }: {
  imports = [ ./core.nix ./multimedia.nix ./rofi ];
}
