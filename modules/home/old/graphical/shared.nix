{ pkgs, config, lib, ... }:
with lib;
let cfg = config.nixconf.old.graphical;
in {
  options.nixconf.old.graphical.theme = mkOption {
    type = with types; enum [ "breeze" ];
    default = "breeze";
  };

  config = mkIf (cfg.graphical.enable == true) {
    home = {
      sessionVariables = {
        QT_QPA_PLATFORMTHEME = "pop";
        SSH_AUTH_SOCK = "\${XDG_RUNTIME_DIR}/keyring/ssh";
        SSH_ASKPASS = "${pkgs.seahorse}/libexec/seahorse/ssh-askpass";
      };

      packages = with pkgs; [
        xdg-utils

        # Fonts
        noto-fonts-emoji
        selected-nerdfonts
        # google-fonts
        noto-fonts-cjk # Chinese
        dejavu_fonts
        liberation_ttf
        corefonts # microsoft
        carlito
        corefonts
        roboto-slab

        fira-code
        source-code-pro
        fira-mono
        fira-code-symbols
        inconsolata
        emacs-all-the-icons-fonts
        font-awesome
        selected-nerdfonts

        fontpreview
        emote

        seahorse
      ];
    };

    fonts.fontconfig.enable = true;

    gtk = {
      enable = true;
      iconTheme = {
        package = pkgs.pop-gtk-theme;
        name = "pop";
      };

      font = {
        # already installed in profile
        package = null;
        name = "Berkeley Mono Variable";
        size = 10;
      };
    };

    qt = {
      enable = true;
      platformTheme = "gnome";
      style = {
        package = pkgs.pop-gtk-theme;
        name = "pop";
      };
    };

    # https://github.com/nix-community/home-manager/issues/2064
    systemd.user.targets.tray = {
      Unit = {
        Description = "Home manager system tray";
        Requires = [ "graphical-session-pre.target" ];
        After = [ "xdg-desktop-portal-gtk.service" ];
      };
    };

    systemd.user.sessionVariables = {
      # So graphical services are themed (eg trays)
      QT_QPA_PLATFORMTHEME = mkForce "pop";
      PATH = builtins.concatStringsSep ":" [
        # Following two needed for themes from trays
        # "${pkgs.libsForQt5.qtstyleplugin-kvantum}/bin"
        # "${pkgs.qt5ct}/bin"
        # needed for opening things from trays
        # "${pkgs.xdg-utils}/bin"
        # "${pkgs.dolphin}/bin"
      ];
    };

    xdg = {
      systemDirs.data = [
        "${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}"
        "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}"
      ];

      configFile = {
        "wallpapers" = { source = ./wallpapers; };

        "kdeglobals" = {
          text = ''
            [General]
            TerminalApplication=${pkgs.alacritty}/bin/alacritty
          '';
        };
      };

      #   # https://wiki.archlinux.org/title/XDG_MIME_Applications#New_MIME_types
      #   # https://specifications.freedesktop.org/shared-mime-info-spec/shared-mime-info-spec-latest.html#idm46292897757504
      #   # "mime/text/x-r-markdown.xml" = {
      #   #   text = ''
      #   #     <?xml version="1.0" encoding="UTF-8"?>
      #   #     <mime-info xmlns="http://www.freedesktop.org/standards/shared-mime-info">
      #   #       <mime-type type="text/x-r-markdown">
      #   #         <comment>RMarkdown file</comment>
      #   #         <icon name="text-x-r-markdown"/>
      #   #         <glob pattern="*.Rmd"/>
      #   #         <glob pattern="*.Rmarkdown"/>
      #   #       </mime-type>
      #   #     </mime-info>
      #   #   '';
      #   # };
      # };
    };

    # dconf settings set by gtk settings: https://github.com/nix-community/home-manager/blob/693d76eeb84124cc3110793ff127aeab3832f95c/modules/misc/gtk.nix#L227
    dconf.settings = {
      "org/gnome/desktop/interface" = {
        # https://askubuntu.com/questions/1404764/how-to-use-hdystylemanagercolor-scheme
        color-scheme = "prefer-dark";
        text-scaling-factor = 1.0;
      };
    };

    xdg = {
      enable = true;
      mime.enable = true;

      dataFile = {
        "fonts/CascadiaMono" = {
          source = ./myfonts/CascadiaMono;
          recursive = true;
        };
        "fonts/Cousine" = {
          source = ./myfonts/Cousine;
          recursive = true;
        };
        "fonts/DankMono" = {
          source = ./myfonts/DankMono;
          recursive = true;
        };
        "fonts/Menlo" = {
          source = ./myfonts/Menlo;
          recursive = true;
        };
        "fonts/MonoLisa" = {
          source = ./myfonts/MonoLisa;
          recursive = true;
        };
        "fonts/OperatorMono" = {
          source = ./myfonts/OperatorMono;
          recursive = true;
        };
      };
    };
  };
}
