{ inputs, system, overlays, hardwareConfig, diskoConfig, nixosProfiles }:
let
  inherit (inputs) nixpkgs nixos-generators disko home-manager;
  inherit (nixpkgs) lib;
in inputs.nixpkgs.lib.nixosSystem {
  inherit system;
  modules = [
    nixos-generators.nixosModules.all-formats
    disko.nixosModules.disko
    home-manager.nixosModules.home-manager
    # {
    #   home-manager = {
    #     useGlobalPkgs = true;
    #     useUserPackages = true;
    #     users.thongpv87 = {
    #       imports = [
    #         ../modules/home
    #         # nix-doom-emacs.hmModule
    #       ];

    #       home.stateVersion = "23.11";
    #     } // (builtins.foldl' (a: b: lib.attrsets.recursiveUpdate a b) { }
    #       userProfiles);
    #   };

    #   # Optionally, use home-manager.extraSpecialArgs to pass
    #   # arguments to home.nix
    # }

    ({ pkgs, config, lib, modulesPath, ... }:
      {
        imports = [ ../modules/system ../modules/hardware ];

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
