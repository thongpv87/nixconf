let username = "thongpv87";
in {
  users.users."${username}" = {
    isNormalUser = true;
    password = "demo";
    # shell = "${pkgs.zsh}/bin/zsh";
    extraGroups =
      [ "wheel" "networkmanager" "video" "libvirtd" "audio" "docker" ];
    uid = 1000;
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users."${username}" = {
      imports = [ ../home ];

      nixconf = {
        core.enable = true;
        apps = {
          emacs.enable = true;
          rofi.enable = true;
          alacritty.enable = true;
        };

        services = {
          display-manager = {
            enable = true;
            window-manager = "hypr";
          };
        };
      };
      nixconf.old = {
        graphical = {
          enable = true;
          theme = "breeze";
          mime.enable = true;
          applications = { enable = false; };
          xorg = {
            enable = false;
            xmonad = { enable = false; };

            screenlock.enable = false;
          };
        };
        applications = {
          enable = true;
          direnv.enable = true;
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
    };
  };

}
