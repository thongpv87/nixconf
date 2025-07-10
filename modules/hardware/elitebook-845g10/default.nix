{
  pkgs,
  config,
  lib,
  modulesPath,
  ...
}:
let
  cfg = config.nixconf.hardware.elitebook-845g10;
in
{
  options.nixconf.hardware.elitebook-845g10 = {
    enable = lib.mkOption { default = false; };
  };

  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  config = lib.mkIf cfg.enable {
    boot = {
      initrd.availableKernelModules = [
        "nvme"
        "xhci_pci"
        "thunderbolt"
        "usb_storage"
        "sd_mod"
        "amdgpu"
      ];
      kernelModules = [
        "kvm-amd"
        "synaptics_usb"
        "hp-wmi"
        "hp-wmi-sensors"
        "k10temp"
      ];
    };
    services.xserver = {
      videoDrivers = [ "amdgpu" ];
      monitorSection = ''
        DisplaySize 302 189
      '';

    };
    boot.kernelPackages = pkgs.linuxPackages_latest;
    # boot.kernelPackages = pkgs.zen4KernelPackages;

    boot.kernelParams = [ "rtc_cmos.use_acpi_alarm=1" ];

    nix.settings.system-features = [ "gccarch-znver4" ];

    nixpkgs.hostPlatform = {
      system = "x86_64-linux";
    };

    services.keyd = {
      enable = true;
      keyboards = {
        default = {
          ids = [ "*" ];
          settings = {
            main = {
              f2 = "noop";
              f6 = "capslock";
            };
          };
        };
      };
    };

    hardware.amdgpu = {
      opencl.enable = true;
      initrd.enable = true;
      amdvlk = {
        enable = true;
        support32Bit.enable = true;
      };
    };
    hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  };
}
