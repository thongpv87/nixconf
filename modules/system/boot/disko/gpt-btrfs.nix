{ device ? "/dev/nvme0" }: {
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

          root = {
            size = "100%";
            content = {
              type = "btrfs";
              extraArgs = [ "-f" ]; # Override existing partition
              # Subvolumes must set a mountpoint in order to be mounted,
              # unless their parent is mounted
              subvolumes = {
                # local subvolume will be rollback to blank on boot
                "@root" = {
                  mountpoint = "/";
                  mountOptions = [ "compress=zstd" "noatime" ];

                };
                "@home" = {
                  mountOptions = [ "compress=zstd" ];
                  mountpoint = "/home";
                };

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

          swap = {
            size = "40G";
            content = {
              type = "swap";
              randomEncryption = true;
              resumeDevice = true; # resume from hiberation from this device
            };
          };
        };
      };
    };
  };

  nodev = {
    "/tmp" = {
      fsType = "tmpfs";
      mountOptions = [ "size=2G" "defaults" "mode=755" ];
    };
  };
}
