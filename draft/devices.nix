{
  amd-7940hs = cpu {
    vendor = "amd";
    manufacture = "amd";
    generation = "phoenix";
    model = "7940HS";
  };

  amd-780m = gpu {
    vendor = "amd";
    manufacture = "amd";
    generation = "RDNA3";
    model = "780M";
  };

  disk1 = disk {
    type = "nvme";
    vendor = "samsung";
    model = "980-PRO";
  };

  laptop-monitor = {
    width = 2560;
    height = 1600;
    subpixel = "rgb";
    refresh-rate = 120;
    vrr = "no";
  };

  dell-u2720c-monitor = {
    model = "U2720C";
    width = "3840";
    height = "1920";
    refresh-rate = "60";
    sub-pixel = "rgb";
    vrr = "no";
  };

  eth-nic = {
    type = "ethernet-nic";
    bandwidth = "1GBps";
    vendor = "Intel";
  };
  wifi-nic = {
    type = "ethernet-nic";
    bandwidth = "1GBps";
    vendor = "Intel";
  };

  elitebook_845g10 = {
    brand = "hp";
    model = "elitebook_845g10";
    type = "laptop";
    hardware = {
      cpus = [ amd-9740hs ];
      gpus = {
        main = {
          device = amd-780m;
          pcie-socket = "0:01:10";
        };

        extra = [{
          device = nvidia-4080;
          pcie-socket = "1:0:10";
        }];
      };

      disks = { main.device = nvme1; };

      displays = {
        primary = laptop-monitor;
        external = dell-u2720c-monitor;
      };

      networking = { };
    };
  };
}
