{ pkgs, config, lib, modulesPath, ... }:
let cfg = config.nixconf.hardware.elitebook-845g10;
in {
  options.nixconf.hardware.elitebook-845g10 = {
    enable = lib.mkOption { default = false; };
  };

  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  config = lib.mkIf cfg.enable {
    boot = {
      initrd.availableKernelModules =
        [ "nvme" "xhci_pci" "thunderbolt" "usb_storage" "sd_mod" ];
      kernelModules = [ "kvm-amd" "synaptics_usb" ];
    };
    nixpkgs.hostPlatform = "x86_64-linux";
    services.xserver = {
      videoDrivers = [ "amdgpu" ];
      monitorSection = ''
        DisplaySize 302 189
      '';

    };

    systemd.services.systemd-logind.environment = {
      SYSTEMD_BYPASS_HIBERNATION_MEMORY_CHECK = "1";
    };

    boot.kernelPackages = pkgs.linuxPackages_latest;

    hardware.cpu.amd.updateMicrocode =
      lib.mkDefault config.hardware.enableRedistributableFirmware;
  };
}
