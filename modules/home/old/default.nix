{ pkgs, config, lib, ... }: {
  imports = [
    ./applications
    ./graphical
    ./git
    ./gpg
    ./zsh
    ./ssh
    ./terminal
    ./others
  ];
}
