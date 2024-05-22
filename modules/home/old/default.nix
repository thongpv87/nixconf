{ pkgs, config, lib, ... }: {
  imports = [
    ./applications
    ./graphical
    ./git
    ./gpg
    ./ssh
    ./others
  ];
}
