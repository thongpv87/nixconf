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
        enable = true;
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
          "JetBrainsMono Nerd Font"
          "DejaVu Sans Mono"
          "FiraCode Nerd Font"
          "Berkeley Mono"
        ];
        sansSerif = [
          "Roboto"
          "Noto Sans"
          "Arial"
          "Liberation Sans"
        ];
        serif = [
          "Roboto Slab"
          "Noto Serif"
          "Times New Roman"
          "Liberation Serif"
        ];
      };
    };

    gtk = {
      enable = true;
      gtk4.theme = config.gtk.theme;
      theme = {
        package = pkgs.kdePackages.breeze-gtk;
        name = "breeze";
      };
      iconTheme = {
        package = pkgs.kdePackages.breeze-icons;
        name = "breeze";
      };
      font = {
        name = "Roboto Slab";
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
        font-name = "Roboto Slab 11";
        document-font-name = "Roboto Slab 11";
        monospace-font-name = "Berkeley Mono 11";
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
      roboto
      roboto-slab

      # Music
      playerctl

      # Programming
      nodejs
      python3

      # video call
      zoom-us
    ];

    services.playerctld.enable = true;
  };
}
