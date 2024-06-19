{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.nixconf.core;
  inherit (lib)
    mkOption
    mkMerge
    mkIf
    mkDefault
    mkForce
    types
    mdDoc
    mkEnableOption
    ;
in
{
  options.nixconf.core = {
    enable = mkOption {
      default = true;
      description = "Enable core system config";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      neofetch
      ntfs3g
      gnused
      gawkInteractive
      ascii
      file
      shared-mime-info
      ffmpeg_5-full

      binutils
      coreutils
      dnsutils
      killall
      iotop
      wget
      nmap
      curl
      git
      unzip
      direnv
      bottom
      jq
      nix-index
      ripgrep
      fd
      whois
      dosfstools
      gptfdisk
      iputils
      usbutils
      utillinux
      file
      pciutils
      nethogs
      pfetch
      nixvim
      htop
      eza
      fzf
      firefox
      ix
      traceroute
      util-linux
      lm_sensors
      pciutils
      usbutils
      iputils
      usbutils
      ifuse
    ];

    time.timeZone = mkForce "Asia/Ho_Chi_Minh";
    i18n.inputMethod = {
      # enabled = "ibus";
      # ibus.engines = with pkgs.ibus-engines; [ bamboo ];
      enabled = "fcitx5";
      fcitx5 = {
        waylandFrontend = true;
        addons = [ pkgs.fcitx5-gtk pkgs.fcitx5-bamboo ];
      };
    };

    security = {
      polkit.enable = true;
      rtkit.enable = true;
    };
    services = {
      pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
        jack.enable = true;
      };
      printing.enable = false;
      avahi = {
        enable = false;
        nssmdns4 = false;
        openFirewall = config.service.avahi.enable;
      };

      chrony = {
        enable = true;
        extraConfig = ''
          pool time.google.com       iburst minpoll 1 maxpoll 2 maxsources 3
          pool ntp.ubuntu.com        iburst minpoll 1 maxpoll 2 maxsources 3
          pool us.pool.ntp.org       iburst minpoll 1 maxpoll 2 maxsources 3

          maxupdateskew 5.0
          makestep 0.1 -1
        '';
      };

      timesyncd.enable = false;

      fwupd = {
        enable = true;
        extraRemotes = [ "lvfs-testing" ];
      };
    };

    nixpkgs.config.allowUnfree = true;

    nix = {
      gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 30d";
      };

      settings = {
        sandbox = true;

        trusted-users = [
          "root"
          "@wheel"
        ];
        allowed-users = [ "@wheel" ];
        system-features = [
          "benchmark"
          "big-parallel"
          "kvm"
          "nixos-test"
        ];

        auto-optimise-store = true;
      };

      extraOptions = ''
        experimental-features = nix-command flakes
        min-free = 536870912
        keep-outputs = true
        keep-derivations = true
        fallback = true
      '';
    };

    boot.kernel.sysctl = {
      "vm.swappiness" = 30;
    };

    system.stateVersion = lib.mkDefault "23.11";
  };
}
