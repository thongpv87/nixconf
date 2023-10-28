{ config, pkgs, lib, ... }:
let
  cfg = config.nixconf.boot;
  inherit (lib)
    mkOption mkMerge mkIf mkDefault mkForce types mdDoc mkEnableOption;

  msdosLayouts = {
    msdos-btrfs = import ./disko/bios-btrfs.nix;
    msdos-btrfs-tmpfs = import ./disko/bios-btrfs-tmpfs.nix;
  };
  gptLayouts = {
    gpt-btrfs-tmpfs-rollback = import ./disko/gpt-btrfs-tmpfs-rollback.nix;
    gpt-btrfs = import ./disko/gpt-btrfs.nix;
  };
  diskLayouts = msdosLayouts // gptLayouts;
  diskLayoutNames = lib.concatMap lib.attrNames diskLayouts;
  diskoDevice = diskLayouts.${cfg.diskLayout} { inherit (cfg) device; };

  isGptDiskLayout = lib.elem cfg.diskLayout (lib.attrNames gptLayouts);
  isMsdosDiskLayout = lib.elem cfg.diskLayout (lib.attrNames msdosLayouts);
in {
  options.nixconf.boot = {
    mode = mkOption {
      type = types.enum [ "bios" "efi" ];
      default = "efi";
    };

    diskLayout = mkOption {
      type = types.enum [ "msdos-btrfs" "gpt-btrfs" ]; # diskLayoutNames;
      default = "gpt-btrfs";
    };
    bootloader = mkOption {
      type = types.enum [ "systemd-boot" "grub" ];
      default = "systemd-boot";
    };
    device = mkOption {
      type = types.str;
      example = "/dev/sda";
    };
  };

  config = lib.mkMerge [
    {
      disko.devices = diskoDevice;
      boot.loader.grub.devices = [ cfg.device ];
      #swapDevices = [{ device = "/dev/disk/by-partlabel/disk-main-swap"; }];
    }
    (lib.mkIf (cfg.bootloader == "systemd-boot") {
      assertions = [
        {
          assertion = isGptDiskLayout;
          message =
            "${cfg.diskLayout} does not compatible with ${cfg.bootloader} bootloader";
        }
        {
          assertion = cfg.mode != "bios";
          message =
            "${cfg.bootloader} bootloader does not compatible with ${cfg.mode} boot mode";
        }
      ];

      boot = {
        loader = {
          systemd-boot.enable = true;
          systemd-boot.netbootxyz.enable = true;

          efi.canTouchEfiVariables = true;
          efi.efiSysMountPoint = "/boot";
        };
        # NOTE: systemd stage 1 does not support 'boot.growPartition' yet.
        growPartition = lib.mkForce false;
      };
    })
    (lib.mkIf (cfg.bootloader == "grub") {
      assertions = [{
        assertion = (cfg.mode == "bios" && isMsdosDiskLayout)
          || (cfg.mode == "efi" && isGptDiskLayout);
        message =
          "${cfg.diskLayout} does not compatible with ${cfg.mode} boot mode";
      }];

      boot.loader = {
        efi = { canTouchEfiVariables = true; };
        grub = {
          efiSupport = true;
          device = cfg.device;
        };
      };
    })
  ];
}
