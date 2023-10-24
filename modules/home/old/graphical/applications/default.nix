{ pkgs, config, lib, ... }: {
  imports = [
    ./core.nix
    ./libreoffice.nix
    ./anki.nix
    ./multimedia.nix
    ./kdeconnect.nix
    ./rofi
  ];
}
