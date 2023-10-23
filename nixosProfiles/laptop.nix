{
  nixconf = {
    hardware.virtualbox.enable = true;
    boot = {
      mode = "bios";
      diskLayout = "msdos-btrfs";
      bootloader = "grub";
      device = "/dev/sda";
    };

  };
}
