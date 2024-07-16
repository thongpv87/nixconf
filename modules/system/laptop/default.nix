{
  pkgs,
  config,
  lib,
  modulesPath,
  ...
}:
let
  cfg = config.nixconf.laptop;
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
in
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    ./power-management
  ];

  options.nixconf.laptop = {
    enable = mkOption { default = false; };
    tlp = mkOption {

    };
  };

  config = lib.mkIf cfg.enable {

    environment.systemPackages = with pkgs; [
      acpid
      powertop
      acpi
      dosfstools
      gptfdisk
      wirelesstools
    ];

    programs = {
      light.enable = true;
    };

    boot = {
      kernelModules = [ "acpi_call" ];
      extraModulePackages = [ config.boot.kernelPackages.acpi_call ];
    };

    services = {
      fstrim.enable = true;
      udev.packages = with pkgs; [ gnome.gnome-settings-daemon ];
      upower.enable = true;
      fprintd.enable = true;
      blueman.enable = config.hardware.bluetooth.enable;

      # Hibernate on low battery. from: https://wiki.archlinux.org/title/laptop#Hibernate_on_low_battery_level
      udev.extraRules = ''
        # Suspend the system when battery level drops to 5% or lower
        SUBSYSTEM=="power_supply", ATTR{status}=="Discharging", ATTR{capacity}=="[0-5]", RUN+="${pkgs.systemd}/bin/systemctl suspend"
        # SUBSYSTEM=="power_supply", ATTR{status}=="Discharging", ATTR{capacity}=="[0-5]", RUN+="${pkgs.systemd}/bin/systemctl hibernate"
      '';

      logind = {
        # idleaction with startx: https://bbs.archlinux.org/viewtopic.php?id=207536
        # <LeftMouse>https://wiki.archlinux.org/title/Power_management
        # Options: ttps://www.freedesktop.org/software/systemd/man/logind.conf.html
        extraConfig = ''
          HandleLidSwitch=suspend
          HandlePowerKey=suspend
          HandleLidSwitchDocked=ignore
          IdleAction=suspend
          IdleActionSec=30min
        '';
      };

      acpid = {
        # NixOS source: https://github.com/NixOS/nixpkgs/blob/nixos-21.05/nixos/modules/services/hardware/acpid.nix
        # acpid info: https://wiki.archlinux.org/title/acpid
        enable = true;
        handlers = {
          # Volume not controllable from acpid as pulseaudio is user service and acpid is system
          brightness-down = {
            event = "video/brightnessdown*";
            action = "${pkgs.light}/bin/light -U 5";
          };
          brightness-up = {
            event = "video/brightnessup";
            action = "${pkgs.light}/bin/light -A 5";
          };
          ac-power = {
            event = "ac_adapter/*";
            action = ''
              vals=($1)  # space separated string to array of multiple values
              case ''${vals[3]} in
                00000000|00000001)
                  max_bright=30
                  curr_bright=$(echo $(${pkgs.light}/bin/light -G) | xargs printf "%0.f")
                  ${pkgs.light}/bin/light -S $((curr_bright<max_bright ? curr_bright : max_bright))
                  ;;
              esac
            '';
          };
        };
      };
    };

    hardware = {
      bluetooth = {
        enable = true;
        settings = {
          General = {
            Enable = "Source,Sink,Media,Socket";
          };
        };
      };
    };
  };
}
