{ device ? "/dev/nvme" }:
#TODO: swapfile

{
  disk = {
    main = {
      inherit device;
      type = "disk";
      content = {
        type = "table";
        format = "msdos";
        partitions = [{
          name = "MAIN";
          start = "1MB";
          end = "100%";
          bootable = true;
          content = {
            type = "btrfs";
            extraArgs = [ "-f" ];
            subvolumes = {
              "@boot" = {
                mountpoint = "/boot";
                mountOptions = [ "compress=zstd" "noatime" ];
              };
              "@nix" = {
                mountpoint = "/nix";
                mountOptions = [ "compress=zstd" "noatime" ];
              };
              "@persist" = {
                mountpoint = "/persist";
                mountOptions = [ "compress=zstd" "noatime" ];
              };
            };
          };
        }];
      };
    };
  };

  nodev = {
    "/" = {
      fsType = "tmpfs";
      mountOptions = [ "size=3G" "mode=755" ];
    };
  };
}
