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
        [ "nvme" "xhci_pci" "thunderbolt" "usb_storage" "sd_mod" "amdgpu" ];
      kernelModules =
        [ "kvm-amd" "synaptics_usb" "hp-wmi" "hp-wmi-sensors" "k10temp" ];
    };
    nixpkgs.hostPlatform = "x86_64-linux";
    services.xserver = {
      videoDrivers = [ "amdgpu" ];
      monitorSection = ''
        DisplaySize 302 189
      '';

    };
    boot.blacklistedKernelModules = [ "amd_pmf" ];

    boot.kernelPackages = pkgs.linuxPackages_latest;
    powerManagement.enable = false;

    hardware.cpu.amd.updateMicrocode =
      lib.mkDefault config.hardware.enableRedistributableFirmware;
  };
}
