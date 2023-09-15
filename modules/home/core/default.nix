{ pkgs, config, lib, ... }:
with lib;
let cfg = config.nixconf.core;
in {

  options.nixconf.core = {
    enable = mkOption {
      description = "Enable a set of common applications";
      type = types.bool;
      default = false;
    };
  };

  config = mkIf (cfg.enable) {
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;

    };

    home.sessionVariables = { EDITOR = "vim"; };

    xdg.enable = true;

    # TTY compatible CLI applications
    home.packages = with pkgs; [
      home-manager

      # CLI tools
      glow
      yt-dlp # download youtube
      graphviz # dot

      # Spell checking
      # Setting up dictionary modified from:
      hunspell
      hunspellDicts.en_US-large
      hyphen
      nixfmt

      # Themes
      theme-sh

      # music
      playerctl
    ];

    services.playerctld.enable = true;
  };
}
