{
  config,
  pkgs,
  lib,
  ...
}:
with lib;
let
  cfg = config.nixconf.apps.neovim;
  neovimPkgs = pkgs.neovim.override { withNodeJs = true; };

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
  myvim = pkgs.writeShellScriptBin "vim" ''
    #!/usr/bin/env bash
    ${neovimPkgs}/bin/nvim $@
  '';
in
{
  options.nixconf.apps.neovim = {
    enable = mkOption {
      description = "Enable neovim with lazyvim config";
      type = types.bool;
      default = false;
    };
  };

  config = mkIf cfg.enable {

    home.packages = with pkgs; [
      neovimPkgs
      myvim
      sqlite
      gcc
      lazygit
      ripgrep
      fd
      coreutils
      fd
      gnumake
      git
      nixd
      selected-nerdfonts
      luarocks
      lua
      cargo
      zlib
      zlib.dev
      #nodejs
      stack
    ];
  };
}
