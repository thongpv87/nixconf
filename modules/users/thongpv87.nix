let
  username = "thongpv87";
in
{
  users.users."${username}" = {
    isNormalUser = true;
    password = "demo";
    #shell = "${pkgs.zsh}/bin/zsh";
    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
      "libvirtd"
      "audio"
      "docker"
    ];
    uid = 1000;
  };

  home-manager = {
    backupFileExtension = "bk";
    useGlobalPkgs = true;
    useUserPackages = true;
    users."${username}" = {
      imports = [ ../home ];

      nixconf = {
        core.enable = true;
        apps = {
          enable = true;
          emacs.enable = false;
          neovim.enable = true;
          rofi.enable = true;
          alacritty.enable = true;
        };

        services = {
          display-manager = {
            enable = true;
            window-manager = "hyprland";
          };
        };

        terminal = {
          enable = true;
          zsh.enable = true;
          nushell.enable = true;
          tmux.enable = true;
          tmux.shell = "zsh";
        };
      };
      nixconf.core = {
        git.enable = true;
        ssh.enable = true;
        gpg.enable = true;
      };

      home.stateVersion = "25.11";
    };
  };

}
