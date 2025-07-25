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
    astal = {
      url = "github:aylur/astal";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # hyprland = {
    #   url = "github:hyprwm/Hyprland?submodules=1";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
    # hyprpaper = {
    #   url = "github:hyprwm/hyprpaper";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
    # hyprpanel = {
    #   url = "github:Jas-SinghFSU/HyprPanel";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
    #
    quickshell = {
      # add ?ref=<tag> to track a tag
      url = "git+https://git.outfoxxed.me/outfoxxed/quickshell";

      # THIS IS IMPORTANT
      # Mismatched system dependencies will lead to crashes and other issues.
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      systems,
      flake-utils,
      nixpkgs,
      agenix,
      home-manager,
      disko,
      nixos-generators,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      lib = import ./lib { inherit inputs; };
      overlays = import ./overlays { inherit inputs; };
      nixosProfiles = import ./nixosProfiles;
      users = import ./modules/users;
    in
    {
      formatter = nixpkgs.legacyPackages.${system}.nixpkgs-fmt;

      nixosConfigurations = {
        laptop = import ./lib/makeHost.nix {
          inherit inputs system overlays;
          hardwareConfig = { };
          diskoConfig = { };
          nixosProfiles = with nixosProfiles; [
            laptop
            users.thongpv87
          ];
        };

        minimal = inputs.nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            nixos-generators.nixosModules.all-formats
            (
              {
                pkgs,
                config,
                lib,
                modulesPath,
                ...
              }:
              {
                services.openssh = {
                  enable = true;
                  settings.GatewayPorts = "yes";
                };
                users.users.root = {
                  openssh.authorizedKeys.keys = [
                    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOJBQfrG9BfJHmPBas2ZgkjgjjKPfJbGUhIOs4GNsnvm thongpv87@thinkpad"
                  ];
                };
                nixpkgs = {
                  inherit overlays;
                  config.allowUnfree = true;
                };
              }
            )
          ];
        };
      };
    };
}
