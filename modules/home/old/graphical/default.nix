{ pkgs, config, lib, ... }:
with lib;
let
  cfg = config.nixconf.old.graphical;
  my-gsettings-desktop-schemas =
    let defaultPackages = with pkgs; [ gsettings-desktop-schemas gtk3 ];
    in pkgs.runCommand "nixos-gsettings-desktop-schemas" {
      preferLocalBuild = true;
    } ''
      mkdir -p $out/share/gsettings-schemas/nixos-gsettings-overrides/glib-2.0/schemas
      ${concatMapStrings (pkg: ''
        cp -rf ${pkg}/share/gsettings-schemas/*/glib-2.0/schemas/*.xml $out/share/gsettings-schemas/nixos-gsettings-overrides/glib-2.0/schemas
      '') (defaultPackages)}
      # cp -f ${pkgs.gnome.gnome-shell}/share/gsettings-schemas/*/glib-2.0/schemas/*.gschema.override $out/share/gsettings-schemas/nixos-gsettings-overrides/glib-2.0/schemas

      chmod -R a+w $out/share/gsettings-schemas/nixos-gsettings-overrides
      ${pkgs.glib.dev}/bin/glib-compile-schemas $out/share/gsettings-schemas/nixos-gsettings-overrides/glib-2.0/schemas/
    '';
in {
  imports = [ ./applications ./xorg ./config.nix ./mime.nix ];

  options.nixconf.old.graphical = {
    enable = mkOption {
      description = "Enable xorg";
      default = false;
    };

    theme = mkOption {
      type = with types; enum [ "breeze" "pop" ];
      default = "pop";
    };
  };

  config = mkIf cfg.enable {
    home = {
      sessionVariables = {
        QT_QPA_PLATFORMTHEME = mkForce "pop";
        SSH_AUTH_SOCK = "\${XDG_RUNTIME_DIR}/keyring/ssh";
        SSH_ASKPASS = "${pkgs.gnome.seahorse}/libexec/seahorse/ssh-askpass";
        NIX_GSETTINGS_OVERRIDES_DIR =
          "${my-gsettings-desktop-schemas}/share/gsettings-schemas/nixos-gsettings-overrides/glib-2.0/schemas";
      };

      packages = with pkgs; [
        #gsettings-schema
        glib
        gsettings-desktop-schemas
        gtk3
        # qt
        breeze-qt5

        xdg-utils

        # Fonts
        selected-nerdfonts
        noto-fonts-emoji
        # google-fonts

        # bm-font
        noto-fonts-cjk # Chinese
        dejavu_fonts
        liberation_ttf
        corefonts # microsoft
        carlito

        fontpreview
        emote
        #openmoji-color

        gnome.seahorse

        pop-gtk-theme
        numix-icon-theme
        pop-icon-theme
      ];
    };

    # https://github.com/nix-community/home-manager/issues/2064
    # systemd.user.targets.tray = {
    #   Unit = {
    #     Description = "Home manager system tray";
    #     Requires = [ "graphical-session-pre.target" ];
    #     After = [ "xdg-desktop-portal-gtk.service" ];
    #   };
    # };

    systemd.user.sessionVariables = {
      # So graphical services are themed (eg trays)
      PATH = builtins.concatStringsSep ":" [
        # Following two needed for themes from trays
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
      mimeApps = { enable = true; };
    };
  };

}
