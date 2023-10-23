{
  inputs = {
    systems.url = "github:nix-systems/x86_64-linux"; # or x86_64-linux
    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.systems.follows = "systems";
    };

    nixpkgs.url = "nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    haumea = {
      url = "github:nix-community/haumea/v0.2.2";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixvim = {
      url = "github:nix-community/nixvim";
      inputs = { nixpkgs.follows = "nixpkgs"; };
    };

    nix-doom-emacs = {
      url = "github:nix-community/nix-doom-emacs?ref=develop";
      inputs = {
        # nixpkgs.follows = "nixpkgs";
        # emacs-overlay.inputs.nixpkgs.follows = "nix-doom-emacs/nixpkgs";
        #flake-compat.follows = "";
      };
    };
  };

  outputs = { self, systems, haumea, flake-utils, nixpkgs, agenix, home-manager
    , disko, nixos-generators, nixvim, ... }@inputs:
    let
      system = "x86_64-linux";
      lib = import ./lib { inherit inputs; };
      overlays = import ./overlays { inherit inputs; };
      nixosProfiles = import ./nixosProfiles;
      userProfiles = import ./userProfiles;
    in {
      nixosConfigurations = {
        bootstrap = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            ./nixos/bootstrap.nix

            nixos-generators.nixosModules.all-formats
            disko.nixosModules.disko

            ({ pkgs, config, lib, modulesPath, ... }:
              let
                os = import ./modules/os {
                  inherit haumea pkgs config lib modulesPath;
                };

              in {
                imports = [
                  {
                    disko.devices = import modules/os/disko/bios-btrfs.nix {
                      device = "/dev/sda";
                    };
                    boot.loader.grub.devices = [ "/dev/sda" ];
                  }
                  ./modules/os/hardware/virtualbox
                ];

                nixpkgs = {
                  inherit overlays;
                  config = {
                    permittedInsecurePackages = [
                      "electron-9.4.4"
                      "electron-11.5.0"
                      #"qtwebkit-5.212.0-alpha4"
                    ];
                    allowUnfree = true;
                  };
                };
                system.stateVersion = lib.mkForce "23.05";
              })
          ];
        };

        test = import ./lib/makeHost.nix {
          inherit inputs system overlays;
          hardwareConfig = { };
          diskoConfig = { };
          nixosProfiles = with nixosProfiles; [ laptop ];
          userProfiles = [ userProfiles.thongpv87 ];
        };
      };

    };
}
