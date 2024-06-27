{
  nixconf = {
    hardware.elitebook-845g10.enable = true;
    core.enable = true;

    apps = {
      enable = true;
    };

    adhoc.enable = true;

    laptop = {
      enable = true;
      power-management = {
        enable = true;
        useTlp = false;
      };
    };

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

    networking = {
      enable = true;
      encrypted-dns.enable = false;
    };

    services = {
      enable = true;
      ios-support.enable = true;
      virtualisation = {
        enable = true;
        enablePodman = true;
        enableVirtualBox = false;
      };
    };
  };

  networking.networkmanager.enable = true;
  networking.firewall = {
    enable = false;
    allowedTCPPorts = [
      22
      80
      443
      8080
      4000
    ];
  };
}
