{
  nixconf = {
    hardware.elitebook-845g10.enable = true;
    boot = {
      mode = "efi";
      diskLayout = "gpt-btrfs";
      bootloader = "systemd-boot";
      device = "/dev/nvme0n1";
    };
    graphical = {
      enable = true;
      desktopEnv = "xmonad";
    };
  };

  networking.networkmanager.enable = true;
}
