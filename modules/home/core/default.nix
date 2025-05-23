{
  pkgs,
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.nixconf.core;
in
{

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
      sessionVariables = {
        EDITOR = "${pkgs.neovim}/bin/nvim";
        DIRENV_LOG_FORMAT = "";
      };
      stateVersion = "24.11";
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

    fonts.fontconfig = {
      enable = true;
      defaultFonts = {
        emoji = [
          "Noto Color Emoji"
          "JoyPixels"
        ];
        monospace = [
          "Fira Mono"
          "Hack"
          "DejaVu Sans Mono"
        ];
        sansSerif = [
          "Noto Sans"
          "Arial"
          "Liberation Sans"
        ];
        serif = [
          "Noto Serif"
          "Times New Roman"
          "Liberation Serif"
        ];
      };
    };

    gtk = {
      enable = true;
      theme = {
        package = pkgs.kdePackages.breeze-gtk;
        name = "breeze";
      };
      iconTheme = {
        package = pkgs.kdePackages.breeze-icons;
        name = "breeze";
      };
      font = {
        name = "Berkeley Mono Variable";
        size = 11;
      };
    };

    qt = {
      enable = true;
      platformTheme.name = "breeze";
      style = {
        package = pkgs.kdePackages.breeze;
        name = "breeze";
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
      nixfmt-rfc-style

      # Themes
      theme-sh

      # music
      playerctl
    ];

    services.playerctld.enable = true;
  };
}
