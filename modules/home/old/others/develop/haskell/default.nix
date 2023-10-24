{ config, lib, pkgs, ... }:
with lib;
let cfg = config.nixconf.old.others.develop.haskell;
in {
  options = {
    thongpv87.others.develop.haskell.enable = mkOption { default = false; };
  };

  config = mkIf cfg.enable {
    home.file = {
      ".cabal/config".source = ./toolchain/cabal.config;
      ".stack/config.yaml".source = ./toolchain/stack.config.yaml;
    };

    home.packages = with pkgs; [
      stack
      ghc
      haskellPackages.haskell-language-server
    ];
  };
}
