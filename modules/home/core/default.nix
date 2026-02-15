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
  imports = [
    ./git.nix
    ./ssh.nix
    ./gpg.nix
  ];

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
        SSH_AUTH_SOCK = "\${XDG_RUNTIME_DIR}/keyring/ssh";
      };
      stateVersion = "25.11";
      pointerCursor = {
        gtk.enable = true;
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

    xdg = {
      enable = true;
      systemDirs.data = [
        "${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}"
        "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}"
      ];
    };

    dconf.settings = {
      "org/gnome/desktop/interface" = {
        color-scheme = "prefer-dark";
        text-scaling-factor = 1.0;
      };
    };

    home.packages = with pkgs; [
      home-manager

      # CLI tools
      glow
      yt-dlp
      graphviz
      sshfs
      pdftk
      asciinema

      # Spell checking
      hunspell
      hunspellDicts.en_US-large
      hyphen
      nixfmt

      # Themes
      theme-sh

      # Desktop integration
      glib
      gsettings-desktop-schemas
      gtk3
      kdePackages.breeze-gtk
      xdg-utils
      seahorse

      # Fonts
      selected-nerdfonts
      noto-fonts-color-emoji
      noto-fonts-cjk-sans
      dejavu_fonts
      liberation_ttf
      corefonts
      carlito

      # Music
      playerctl
    ];

    services.playerctld.enable = true;
  };
}
