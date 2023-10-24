{ config, pkgs, lib, ... }:
let
  cfg = config.nixconf.core;
  inherit (lib)
    mkOption mkMerge mkIf mkDefault mkForce types mdDoc mkEnableOption;
in {
  options.nixconf.core = {
    enable = mkOption {
      default = true;
      description = "Enable core system config";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.binutils
      pkgs.coreutils
      pkgs.dnsutils
      pkgs.nmap
      pkgs.curl
      pkgs.git
      pkgs.direnv
      pkgs.bottom
      pkgs.jq
      pkgs.nix-index
      pkgs.ripgrep
      pkgs.fd
      pkgs.whois
      pkgs.dosfstools
      pkgs.gptfdisk
      pkgs.iputils
      pkgs.usbutils
      pkgs.utillinux
      pkgs.file
      pkgs.pciutils
      pkgs.nethogs
      pkgs.pfetch
      pkgs.neovim
      pkgs.htop
      pkgs.eza
      pkgs.fzf
      pkgs.firefox
    ];

    nix = {
      gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 60d";
      };

      settings = {
        sandbox = true;

        trusted-users = [ "root" "@wheel" ];
        allowed-users = [ "@wheel" ];

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

    boot.kernel.sysctl = { "vm.swappiness" = 30; };

    system.stateVersion = lib.mkDefault "23.11";
  };
}
