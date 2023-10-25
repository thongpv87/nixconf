{ config, pkgs, lib, ... }: {
  programs.emacs = {
    enable = true;
    package = pkgs.emacsPgtk;
  };
  xdg.configFile."doom" = {
    source = ./doom.d;
    recursive = true;
  };
}
