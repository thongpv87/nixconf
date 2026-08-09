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
          "Inter"
          "SF Pro Text"
          "Noto Sans"
          "Arial"
          "Liberation Sans"
        ];
        serif = [
          "Noto Serif"
          "STIX Two Text"
          "Times New Roman"
          "Liberation Serif"
        ];
      };
    };

    gtk = {
      enable = true;
      gtk4.theme = config.gtk.theme;
      gtk3.bookmarks = [
        "file://${config.home.homeDirectory}/Code"
      ];
      theme = {
        package = pkgs.kdePackages.breeze-gtk;
        name = "breeze";
      };
      iconTheme = {
        package = pkgs.kdePackages.breeze-icons;
        name = "breeze";
      };
      font = {
        name = "Inter";
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
        font-name = "Inter 11";
        document-font-name = "Inter 11";
        monospace-font-name = "JetBrainsMono Nerd Font 11";
      };
    };

    xdg.userDirs = {
      enable = true;
      createDirectories = true;
      desktop = "${config.home.homeDirectory}/Desktop";
      documents = "${config.home.homeDirectory}/Documents";
      download = "${config.home.homeDirectory}/Downloads";
      music = "${config.home.homeDirectory}/Music";
      pictures = "${config.home.homeDirectory}/Pictures";
      publicShare = "${config.home.homeDirectory}/Public";
      templates = "${config.home.homeDirectory}/Templates";
      videos = "${config.home.homeDirectory}/Videos";
    };

    home.packages = with pkgs; [
      home-manager
      xdg-user-dirs
      xdg-user-dirs-gtk

      # CLI tools
      glow
      yt-dlp
      graphviz
      sshfs
      pdftk
      kdePackages.okular
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
      inter
      stix-two
      selected-nerdfonts
      noto-fonts-color-emoji
      noto-fonts-cjk-sans
      dejavu_fonts
      liberation_ttf
      corefonts
      carlito
      roboto

      # Music
      playerctl

      # Programming
      nodejs
      python3
      alacritty
      kitty

      # video call
      zoom-us
    ];

    services.playerctld.enable = true;
  };
}
