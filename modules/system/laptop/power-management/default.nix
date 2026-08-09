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
    useTlp = mkOption {
      type = types.bool;
      default = true;
      description = "Enable TLP for laptop power management";
    };
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

            # Platform Profile tuning for HP EliteBook
            PLATFORM_PROFILE_ON_AC = "balanced";
            PLATFORM_PROFILE_ON_BAT = "low-power";

            # AMD P-State EPP Driver tuning for Ryzen 7000 (Phoenix)
            CPU_SCALING_GOVERNOR_ON_AC = "powersave";
            CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
            CPU_ENERGY_PERF_POLICY_ON_AC = "balance_performance";
            CPU_ENERGY_PERF_POLICY_ON_BAT = "balance_power";

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
