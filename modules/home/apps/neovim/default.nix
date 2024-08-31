{
  config,
  pkgs,
  lib,
  ...
}:
with lib;
let
  cfg = config.nixconf.apps.neovim;
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
    ${pkgs.neovim}/bin/nvim $@
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
      neovim
      myvim
      sqlite
      gcc
      lazygit
      ripgrep
      fd
      coreutils
      fd
      git
      nixd
      selected-nerdfonts
    ];

    xdg.configFile."nvim" = {
      source = ./nvim;
      recursive = true;
    };

    # home.activation = {
    #   myActivationAction = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    #     run cp -r $HOME/.local/share/nvim $HOME/.config
    #     chmod -R 600 $HOME/.config/nvim
    #   '';
    # };
  };
}
