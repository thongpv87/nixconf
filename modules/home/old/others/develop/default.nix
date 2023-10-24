{ config, lib, pkgs, ... }: {
  imports = [ ./haskell ./agda ];

  # home.packages = [ (pkgs.agda.withPackages (p: [ p.standard-library ])) ];
  # services.emacs = {
  #   enable = true;
  #   defaultEditor = true;
  # };
}
