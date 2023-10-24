{ config, pkgs, lib, ... }:
let
  cfg = config.nixconf.adhoc;
  inherit (lib)
    mkOption mkMerge mkIf mkDefault mkForce types mdDoc mkEnableOption;
in {
  options.nixconf.adhoc = { enable = mkEnableOption "Enable adhoc configs"; };

  config = mkIf cfg.enable (mkMerge [

    # power management configs
    {
      services.power-profiles-daemon.enable = false;
      services.tlp = {
        enable = true;
        settings = {
          NMI_WATCHDOG = mkForce 0;
          RADEON_DPM_PERF_LEVEL_ON_AC = "auto";
          RADEON_DPM_PERF_LEVEL_ON_BAT = "low";
          # Check the output of tlp-stat -p to determine availability on your hardware
          # and additional profiles such as balanced-performance, quiet, cool.
          PLATFORM_PROFILE_ON_BAT = "low-power";

          CPU_DRIVER_OPMODE_ON_AC = "guided";
          CPU_DRIVER_OPMODE_ON_BAT = "guided";

          # CPU_SCALING_GOVERNOR_ON_AC = "schedutil";
          # CPU_SCALING_GOVERNOR_ON_BAT = "schedutil";
          # For available frequencies consult the output of tlp-stat -p.
          # CPU_SCALING_MIN_FREQ_ON_AC = 0;
          # CPU_SCALING_MAX_FREQ_ON_AC = 9999999;
          # CPU_SCALING_MIN_FREQ_ON_BAT = 0;
          # CPU_SCALING_MAX_FREQ_ON_BAT = 9999999;
          #
          CPU_BOOST_ON_AC = 0;
          CPU_BOOST_ON_BAT = 0;
          DEVICES_TO_DISABLE_ON_STARTUP = "bluetooth wwan";
          DEVICES_TO_ENABLE_ON_STARTUP = "wifi";
          DEVICES_TO_DISABLE_ON_BAT_NOT_IN_USE = "bluetooth wwan";
          DEVICES_TO_DISABLE_ON_WIFI_CONNECT = "wwan";

          # Runtime Power Management and ASPM
          RUNTIME_PM_ON_AC = "auto";
          RUNTIME_PM_ON_BAT = "auto";
          PCIE_ASPM_ON_AC = "powersave";
          PCIE_ASPM_ON_BAT = "powersave";
        };
      };

      boot = mkIf config.services.tlp.enable {
        kernelModules = [ "acpi_call" ];
        extraModulePackages = [ config.boot.kernelPackages.acpi_call ];
      };
    }
    #ssd
    { services.fstrim.enable = lib.mkDefault true; }

    {
      time.timeZone = mkForce "Asia/Ho_Chi_Minh";
      i18n.inputMethod = {
        enabled = "ibus"; # "fcitx";
        ibus.engines = with pkgs.ibus-engines; [ bamboo ];

        # fcitx.engines = [ pkgs.fcitx-engines.unikey ];
        # fcitx5.addons = [ pkgs.fcitx5-unikey ];
      };

      networking = {
        wireless.iwd.enable = true;
        networkmanager = {
          enable = true;
          wifi = {
            powersave = true;
            backend = mkForce "iwd";
          };
        };
      };

      hardware = {
        opengl = {
          enable = true;
          driSupport32Bit = true;
          extraPackages = with pkgs; [
            rocm-opencl-icd
            rocm-opencl-runtime
            amdvlk
            libva
          ];
        };
      };

      services = {
        fstrim.enable = true;
        fwupd.enable = true;
        udev.packages = with pkgs; [ gnome.gnome-settings-daemon ];
      };
      services.upower.enable = true;
      services.fprintd.enable = true;
    }
  ]);
}
