{
  nixconf = {
    hardware.elitebook-845g10.enable = true;
    core.enable = true;
    adhoc.enable = true;
    boot = {
      mode = "efi";
      diskLayout = "gpt-btrfs";
      bootloader = "systemd-boot";
      device = "/dev/nvme0n1";
    };

    graphical = {
      enable = true;
      desktopEnv = "hyprland";
    };
    networking.cloudflare-warp = {
      openFirewall = false;
      enable = false;
    };
  };

  networking.networkmanager.enable = true;
  networking.firewall = {
    enable = false;
    allowedTCPPorts = [ 22 80 443 8080 4000 ];
  };
}
