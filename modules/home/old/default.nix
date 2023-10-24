{ pkgs, config, lib, ... }: {
  imports = [
    ./applications
    ./graphical
    ./git
    ./gpg
    ./zsh
    ./nushell
    ./ssh
    ./terminal
    ./others
  ];
}
