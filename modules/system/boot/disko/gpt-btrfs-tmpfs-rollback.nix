{ device ? "/dev/nvme" }: {
  disk = {
    main = {
      inherit device;
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          boot = {
            size = "1M";
            type = "EF02"; # for grub MBR
          };
          ESP = {
            size = "512M";
            type = "EF00";
            label = "boot";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
            };
          };

          luks = {
            size = "100%";
            content = {
              type = "luks";
              name = "enc";
              extraOpenArgs = [ "--allow-discards" ];
              passwordFile = "/tmp/secret.key";
              content = {
                type = "btrfs";
                extraArgs = [ "-f" ]; # Override existing partition
                # Subvolumes must set a mountpoint in order to be mounted,
                # unless their parent is mounted
                subvolumes = {
                  # local subvolume will be rollback to blank on boot
                  "@local" = { };
                  "@local/blank" = { };
                  "@local/root" = { mountpoint = "/"; };
                  "@local/home" = {
                    mountOptions = [ "compress=zstd" ];
                    mountpoint = "/home";
                  };
                  # TODO: swapfile, disable cow for subvolume contains swapfile

                  # Persistent subvolumes
                  "@nix" = {
                    mountOptions = [ "compress=zstd" "noatime" ];
                    mountpoint = "/nix";
                  };
                  "@persist" = {
                    mountOptions = [ "compress=zstd" ];
                    mountpoint = "/persist";
                  };
                };
              };
            };
          };
        };
      };
    };
  };

  nodev = {
    "/var" = {
      fsType = "tmpfs";
      mountOptions = [ "size=2G" "defaults" "mode=755" ];
    };
  };
}
