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

    home = {
      sessionVariables = { EDITOR = "${pkgs.neovim}/bin/nvim"; };
      stateVersion = "23.11";
      pointerCursor = {
        gtk.enable = true;
        # x11.enable = true;
        package = pkgs.pop-icon-theme;
        name = "Pop";
        size = 48;
      };
      keyboard = {
        layout = "us";
        options = [ "caps:escape" ];
      };

    };

    fonts.fontconfig.enable = true;

    gtk = {
      enable = true;
      theme = {
        package = pkgs.pop-gtk-theme;
        name = "Pop";
      };
      iconTheme = {
        package = pkgs.pop-gtk-theme;
        name = "Pop";
      };
      font = {
        name = "Berkeley Mono Variable";
        size = 11;
      };
    };

    qt = {
      enable = true;
      platformTheme = "gnome";
      style = {
        package = pkgs.pop-gtk-theme;
        name = "Pop";
      };
    };

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
