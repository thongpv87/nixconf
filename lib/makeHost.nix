{ inputs, system, overlays, hardwareConfig, diskoConfig, nixosProfiles
, userProfiles }:
let
  inherit (inputs) nixpkgs nixos-generators disko home-manager;
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
          imports = [
            ../modules/home
            # nix-doom-emacs.hmModule
          ];

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

        services.openssh = {
          enable = true;
          settings.GatewayPorts = "yes";
          settings.PasswordAuthentication = true;
        };

        nixpkgs = {
          inherit overlays;
          config = {
            permittedInsecurePackages = [
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
