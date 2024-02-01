{
  nixconf = {
    hardware.virtualbox.enable = true;
    boot = {
      mode = "bios";
      diskLayout = "bios-btrfs";
      bootloader = "systemd-boot";
      device = "/dev/sda";
    };

  };

  # do something with home-manager here, for instance:
  #environment.systemPackages = with pkgs; [ wget vim git ];
  services.openssh = {
    enable = true;
    settings.GatewayPorts = "yes";
    settings.PasswordAuthentication = true;
  };
  networking.networkmanager.enable = true;
  users.users."root".openssh.authorizedKeys.keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCCBoknk64v8xvP7L9LPWb/t+GjsUKS2FH4kpHGJ6yW0JWSU6hfEIsI0zmz6q1En1f/G5jCP26nufhnwanjckeSCIE8dgZzAe8wDtx7j1ndqRZ0ViLq8WZdrbCe1KDcKfu6X5O8c1PlF25n6lgfUAdOL3mwDXntFxiOwDIKQRRrt8JeM59oCNBpU77rUPvV8rQ/rWahWoeMtbUyMAAc20F4rwgZmZzauLlYd6Kgp4JyZ9pBNHpG5a/9bltibGIURupOtu3dCrrTup6Yi4yvWlLZSpfTN0pMrQXIOVM3IIcx7sQ3ONKDjFWLnFiz13yTUUzDxUDUErjDHbeT5zMxG41XBYGkVR2fdyjLdgRDaR+jurKcTop5X/U1o4DUCmED7SPpUCDV29HJ46jM0uzqBTKWU2ovnzKXgLwjxhcuvgb3a4435E7ikNI3elyt+NEBMZIcq9+QN6zwtZebLTFtozEYZ6vGTweorER3BXOcaSXU+VmbwgtZ6HFp+vYkGNBe438= thongpv87@thinkpad"
  ];
}
