{
  pkgs,
  config,
  lib,
  modulesPath,
  ...
}:
let
  cfg = config.nixconf.laptop.power-management;
  inherit (lib)
    mkOption
    mkMerge
    mkIf
    mkDefault
    mkForce
    types
    mdDoc
    mkEnableOption
    ;

  powerOption = {
    scalingDriver = mkOption { type = types.enum [ "amd-pstate-epp" ]; };

    scalingGovernor = mkOption {
      type = types.enum [
        "performance"
        "powersave"
      ];
      default = "powersave";
    };

    enegyPerfomancePreference = mkOption {
      type = types.enum [
        "default"
        "performance"
        "balance_performance"
        "balance_power"
        "power"
      ];
      default = "balance_performance";
    };
  };

  ac-connected = pkgs.writeScriptBin "ac-connected" ''
    #!${pkgs.zsh}/bin/zsh
    # echo "passive" > /sys/devices/system/cpu/amd_pstate/status
    # ${config.boot.kernelPackages.cpupower}/bin/cpupower frequency-set -g schedutil
    echo "active" > /sys/devices/system/cpu/amd_pstate/status
    ${config.boot.kernelPackages.cpupower}/bin/cpupower frequency-set -g performance 
    echo "performance" > /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference
  '';

  ac-disconnected = pkgs.writeScriptBin "ac-disconnected" ''
    #!${pkgs.zsh}/bin/zsh
    echo "active" > /sys/devices/system/cpu/amd_pstate/status
    ${config.boot.kernelPackages.cpupower}/bin/cpupower frequency-set -g powersave
    echo "default" > /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference
  '';
in
{
  options.nixconf.laptop.power-management = {
    enable = mkOption { default = config.nixconf.laptop.enable; };
    useTlp = mkEnableOption { default = false; };
    # onAc = mkOption { type = types.submodule powerOption; };
    # onBat = mkOption { type = types.submodule.powerOption; };
  };

  config = mkIf cfg.enable (mkMerge [
    (mkIf cfg.useTlp {
      powerManagement.enable = false;
      services = {
        power-profiles-daemon.enable = false;
        tlp = {
          enable = true;
          settings = {
            NMI_WATCHDOG = 0;
            RADEON_DPM_PERF_LEVEL_ON_AC = "auto";
            RADEON_DPM_PERF_LEVEL_ON_BAT = "auto";
            # Check the output of tlp-stat -p to determine availability on your hardware
            # and additional profiles such as balanced-performance, quiet, cool.
            PLATFORM_PROFILE_ON_AC = "balanced";
            PLATFORM_PROFILE_ON_BAT = "balanced";

            # CPU_DRIVER_OPMODE_ON_AC = "passive";
            # CPU_DRIVER_OPMODE_ON_BAT = "active";
            # CPU_SCALING_GOVERNOR_ON_AC = "schedutil";
            # CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
            # # CPU_ENERGY_PERF_POLICY_ON_AC = "power";
            # CPU_ENERGY_PERF_POLICY_ON_BAT = "power";

            CPU_HWP_DYN_BOOST_ON_AC = 1;
            CPU_HWP_DYN_BOOST_ON_BAT = 1;

            # DEVICES_TO_DISABLE_ON_BAT_NOT_IN_USE = "bluetooth wwan";
            # DEVICES_TO_DISABLE_ON_WIFI_CONNECT = "wwan";

            # Runtime Power Management and ASPM
            RUNTIME_PM_ON_AC = "auto";
            RUNTIME_PM_ON_BAT = "auto";
            PCIE_ASPM_ON_AC = "default";
            PCIE_ASPM_ON_BAT = "powersave";
          };
        };
      };
    })

    (mkIf (!cfg.useTlp) {
      environment.systemPackages = [
        config.boot.kernelPackages.cpupower
        ac-connected
        ac-disconnected
      ];

      services.udev.extraRules = mkIf (!config.services.tlp.enable) ''
        SUBSYSTEM=="power_supply", ATTR{online}=="1", RUN+="${ac-connected}/bin/ac-connected"
        SUBSYSTEM=="power_supply", ATTR{status}=="Discharging", RUN+="${ac-disconnected}/bin/ac-disconnected"
      '';
    })
  ]);
}
