{ username }:

{
  users.users."${username}" = {
    isNormalUser = true;
    password = "demo";
    # shell = "${pkgs.zsh}/bin/zsh";
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
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "bk";
    users."${username}" = {
      imports = [ ../home ];

      home.stateVersion = "24.11";
    } // (builtins.foldl' (a: b: lib.attrsets.recursiveUpdate a b) { } userProfiles);
  };

}
