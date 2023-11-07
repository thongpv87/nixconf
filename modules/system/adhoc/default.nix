{ config, pkgs, lib, ... }:
let
  cfg = config.nixconf.adhoc;
  inherit (lib)
    mkOption mkMerge mkIf mkDefault mkForce types mdDoc mkEnableOption;
in {
  options.nixconf.adhoc = { enable = mkEnableOption "Enable adhoc configs"; };

  config = mkIf cfg.enable (mkMerge [
    {
      #services.tailscale = { enable = true; };
    }

    # power management configs
    {
      services = {
        power-profiles-daemon.enable = false;

        tlp = {
          enable = true;
          settings = {
            NMI_WATCHDOG = 0;
            RADEON_DPM_PERF_LEVEL_ON_AC = "auto";
            RADEON_DPM_PERF_LEVEL_ON_BAT = "low";
            # Check the output of tlp-stat -p to determine availability on your hardware
            # and additional profiles such as balanced-performance, quiet, cool.
            # PLATFORM_PROFILE_ON_AC = "balanced";
            # PLATFORM_PROFILE_ON_BAT = "balanced";

            CPU_DRIVER_OPMODE_ON_AC = "active";
            CPU_DRIVER_OPMODE_ON_BAT = "active";

            CPU_SCALING_GOVERNOR_ON_AC = "powersave";
            CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
            CPU_ENERGY_PERF_POLICY_ON_AC = "power";
            CPU_ENERGY_PERF_POLICY_ON_BAT = "power";

            CPU_BOOST_ON_AC = 0;
            CPU_BOOST_ON_BAT = 0;
            DEVICES_TO_DISABLE_ON_BAT_NOT_IN_USE = "bluetooth wwan";
            DEVICES_TO_DISABLE_ON_WIFI_CONNECT = "wwan";

            # Runtime Power Management and ASPM
            RUNTIME_PM_ON_AC = "auto";
            RUNTIME_PM_ON_BAT = "auto";
            # PCIE_ASPM_ON_AC = "powersave";
            # PCIE_ASPM_ON_BAT = "powersave";
          };
        };
      };
      boot = mkIf config.services.tlp.enable {

        kernelParams = [
          # "initcall_blacklist=acpi_cpufreq_init"
          # "amd_pstate.enable=true"
          # "amd_pstate=guided"
          # "amd_pstate.shared_mem=1"
        ];
        kernelModules = [ "acpi_call" ];
        extraModulePackages = [ config.boot.kernelPackages.acpi_call ];
      };
    }

    {
      time.timeZone = mkForce "Asia/Ho_Chi_Minh";
      i18n.inputMethod = {
        enabled = "ibus"; # "fcitx";
        ibus.engines = with pkgs.ibus-engines; [ bamboo ];

        # fcitx.engines = [ pkgs.fcitx-engines.unikey ];
        # fcitx5.addons = [ pkgs.fcitx5-unikey ];
      };

      networking = {
        wireless.iwd = {
          #enable = true;
          settings = { Settings = { AutoConnect = true; }; };
        };
        networkmanager = {
          enable = true;
          wifi = {
            powersave = true;
            # backend = mkForce "iwd";
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
    # adhoc
    {
      environment.systemPackages = [
        pkgs.clockify
        pkgs.python3
        pkgs.taskwarrior
        pkgs.timewarrior
        pkgs.taskwarrior-tui
        pkgs.elixir_1_15

        pkgs.shellcheck
        pkgs.nodePackages.bash-language-server

        pkgs.zoom-us
        pkgs.slack
      ];

      services.postgresql = {
        enable = true;
        extraPlugins = with pkgs.postgresql.pkgs; [ timescaledb ];
        authentication = pkgs.lib.mkOverride 10 ''
          #type database  DBuser  auth-method
          local all       all     trust
          host  all       all     127.0.0.1       255.255.255.255     trust
        '';
        settings = { shared_preload_libraries = "timescaledb"; };
      };
    }

    # connectivity
    {
      security.rtkit.enable = true;
      services.pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
        jack.enable = true;
      };
      # TODO: more bluetooth config
      services.printing.enable = false;
      services.avahi.enable = false;
      services.avahi.nssmdns = false;
      services.avahi.openFirewall = config.service.avahi.enable;
      hardware.bluetooth = {
        enable = true;
        settings = { General = { Enable = "Source,Sink,Media,Socket"; }; };
      };
      services.blueman.enable = config.hardware.bluetooth.enable;
    }

    # laptop
    {
      environment.systemPackages = with pkgs; [
        acpid
        powertop
        acpi
        lm_sensors
        dosfstools
        gptfdisk
        iputils
        usbutils
        util-linux
        wirelesstools
        pciutils
        usbutils
        libimobiledevice
        ifuse
      ];
      programs = { light.enable = true; };

      systemd = {
        # Replace suspend mode with hybrid-sleep. So can do hybrid-sleep then hibernate
        sleep.extraConfig = ''
          HibernateDelaySec=30min
        '';
      };

      # https://man.archlinux.org/man/systemd-sleep.conf.5
      # https://www.kernel.org/doc/html/latest/admin-guide/pm/sleep-states.html
      # Suspend mode -> Hybrid-Sleep. This enables hybrid-sleep then hibernate
      services = {
        # better timesync for unstable internet connections
        chrony.enable = true;
        timesyncd.enable = false;
        # iOS mounting
        usbmuxd.enable = true;

        # Hibernate on low battery. from: https://wiki.archlinux.org/title/laptop#Hibernate_on_low_battery_level
        udev.extraRules = ''
          # Suspend the system when battery level drops to 5% or lower
          # SUBSYSTEM=="power_supply", ATTR{status}=="Discharging", ATTR{capacity}=="[0-5]", RUN+="${pkgs.systemd}/bin/systemctl suspend"
          SUBSYSTEM=="power_supply", ATTR{status}=="Discharging", ATTR{capacity}=="[0-5]", RUN+="${pkgs.systemd}/bin/systemctl hibernate"
        '';

        logind = {
          # idleaction with startx: https://bbs.archlinux.org/viewtopic.php?id=207536
          # <LeftMouse>https://wiki.archlinux.org/title/Power_management
          # Options: ttps://www.freedesktop.org/software/systemd/man/logind.conf.html
          extraConfig = ''
            HandleLidSwitch=hibernate
            HandlePowerKey=suspend
            HandleLidSwitchDocked=ignore
            IdleAction=suspend-then-hibernate
            IdleActionSec=5min
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

    }

    {
      programs = {
        dconf.enable = true;
        iftop.enable = true;
        iotop.enable = true;
        nano.syntaxHighlight = true;
        zsh.enable = true;
      };

      services = { usbmuxd.enable = true; };

      environment = {
        systemPackages = with pkgs; [
          #utilities packages
          killall
          pciutils
          htop
          iotop
          neofetch
          ntfs3g
          gnused
          gawkInteractive

          wget
          ascii
          file
          shared-mime-info
          firefox
          google-chrome
          libreoffice-fresh
          nixfmt

          config.boot.kernelPackages.bcc

          # iOS mounting
          libimobiledevice
          ifuse
        ];
        pathsToLink = [ "/share/zsh" ];
      };
    }

    {
      nixpkgs.config.allowUnfree = true;
      virtualisation.virtualbox = { host.enable = true; };
      users.extraGroups.vboxusers.members = [ "thongpv87" ];
    }
  ]);
}
