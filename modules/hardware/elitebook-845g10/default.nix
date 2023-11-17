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
    services.xserver = {
      videoDrivers = [ "amdgpu" ];
      monitorSection = ''
        DisplaySize 302 189
      '';

    };
    # boot.kernelPatches = [{
    #   name = "amd_pmf_freq_lock";
    #   patch = ./amd_pmf_freq_lock.patch;
    # }];
    # boot.blacklistedKernelModules = [ "amd_pmf" ];

    # boot.kernelPackages = pkgs.linuxPackages_testing;
    boot.kernelPackages = pkgs.zen4KernelPackages;

    # boot.kernelParams =
    #   [ ''dyndbg="file drivers/base/firmware_loader/main.c +fmp"'' ];

    nix.settings.system-features = [ "gccarch-znver4" ];

    nixpkgs.hostPlatform = { system = "x86_64-linux"; };
    hardware.cpu.amd.updateMicrocode =
      lib.mkDefault config.hardware.enableRedistributableFirmware;
  };
}
