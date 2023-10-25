{
  nixconf = {
    core.enable = true;
    services = {
      display-manager = {
        enable = true;
        window-manager = "hyprland";
      };
    };
  };
  nixconf.old = {
    graphical = {
      enable = true;
      theme = "breezee";
      mime.enable = true;
      applications = {
        enable = true;
        rofi.enable = true;
        libreoffice.enable = true;
        anki = {
          enable = false;
          sync = false;
        };
        kdeconnect.enable = false;
      };
      wayland = {
        enable = false;
        type = "hyprland";
        background = { enable = false; };
        statusbar = { enable = true; };
        screenlock = {
          enable = false;
          type = "swaylock";
        };
      };
      # xorg = {
      #   enable = true;
      #   xmonad = {
      #     enable = true;
      #     theme = "simple";
      #   };
      #   xmobar.enable = true;

      #   screenlock.enable = false;
      # };
    };
    applications = {
      enable = true;
      direnv.enable = true;
      emacs.enable = true;
    };

    terminal = {
      enable = true;
      tmux = {
        enable = true;
        shell = "zsh";
      };
    };

    gpg.enable = true;
    git = { enable = true; };
    zsh.enable = true;
    ssh.enable = true;
    others.enable = true;
  };
  home.stateVersion = "23.11";
}
