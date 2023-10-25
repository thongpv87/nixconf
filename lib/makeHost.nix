{ inputs, system, overlays, hardwareConfig, diskoConfig, nixosProfiles
, userProfiles }:
let
  inherit (inputs)
    nixpkgs nixos-generators disko home-manager nix-doom-emacs emacs-overlay;
  inherit (nixpkgs) lib;
in inputs.nixpkgs.lib.nixosSystem {
  inherit system;
  modules = [
    nixos-generators.nixosModules.all-formats
    disko.nixosModules.disko
    home-manager.nixosModules.home-manager
    {
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        users.thongpv87 = {
          imports = [ ../modules/home nix-doom-emacs.hmModule ];

          home.stateVersion = "23.11";
        } // (builtins.foldl' (a: b: lib.attrsets.recursiveUpdate a b) { }
          userProfiles);
      };

      # Optionally, use home-manager.extraSpecialArgs to pass
      # arguments to home.nix
    }

    ({ pkgs, config, lib, modulesPath, ... }:
      {
        imports = [ ../modules/system ../modules/hardware ];

        users.users.thongpv87 = {
          isNormalUser = true;
          password = "demo";
          shell = "${pkgs.zsh}/bin/zsh";
          extraGroups =
            [ "wheel" "networkmanager" "video" "libvirtd" "audio" "docker" ];
          uid = 1000;
        };

        #tmp config
        boot = {
          kernelPackages = pkgs.linuxPackages_latest;
          initrd.availableKernelModules =
            [ "nvme" "xhci_pci" "thunderbolt" "usb_storage" "sd_mod" ];
          kernelModules = [ "kvm-amd" ];
        };
        environment.systemPackages = [
          pkgs.vim
          pkgs.dmenu
          pkgs.rofi
          pkgs.alacritty
          pkgs.git
          pkgs.firefox
          pkgs.selected-nerdfonts
        ];
        hardware.cpu.amd.updateMicrocode =
          lib.mkDefault config.hardware.enableRedistributableFirmware;
        networking.networkmanager.enable = true;
        # swapDevices = [{ device = "/dev/disk/by-partlabel/disk-main-swap"; }];

        nixpkgs = {
          inherit overlays;
          config = {
            permittedInsecurePackages = [
              # "electron-9.4.4"
              "electron-11.5.0"
              "electron-24.8.6"
              #"qtwebkit-5.212.0-alpha4"
            ];
            allowUnfree = true;
          };
        };
      } // (builtins.foldl' (a: b: lib.attrsets.recursiveUpdate a b) { }
        nixosProfiles)
      #// import ../nixosProfiles/laptop.nix
    )
  ];
}
