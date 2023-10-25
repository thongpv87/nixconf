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
  };

  networking.networkmanager.enable = true;
}
