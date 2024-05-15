{ config, pkgs, lib, ... }:
let
  cfg = config.nixconf.adhoc;
  inherit (lib)
    mkOption mkMerge mkIf mkDefault mkForce types mdDoc mkEnableOption;
  ac-connected = pkgs.writeScriptBin "ac-connected" ''
    #!${pkgs.zsh}/bin/zsh
    echo "passive" > /sys/devices/system/cpu/amd_pstate/status
    ${config.boot.kernelPackages.cpupower}/bin/cpupower frequency-set -g schedutil
  '';

  ac-disconnected = pkgs.writeScriptBin "ac-disconnected" ''
    #!${pkgs.zsh}/bin/zsh
    echo "active" > /sys/devices/system/cpu/amd_pstate/status
    ${config.boot.kernelPackages.cpupower}/bin/cpupower frequency-set -g powersave
    echo "default" > /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference
  '';

  fake-docker-compose = pkgs.writeScriptBin "docker-compose" ''
    ${pkgs.podman-compose}/bin/podman-compose $@
  '';
in {
  options.nixconf.adhoc = { enable = mkEnableOption "Enable adhoc configs"; };

  config = mkIf cfg.enable (mkMerge [
    {
      services.tailscale = {
        enable = true;
        useRoutingFeatures = "client";
      };
      networking.firewall.enable = false;
    }

    # encrypted dns
    {
      assertions = [{
        assertion = !config.services.resolved.enable;
        message =
          "services.resolved.enable can not use a long with encrypted dns config";
      }];

      networking = {
        nameservers = [ "127.0.0.1" "::1" ];
        # If using dhcpcd:
        dhcpcd.extraConfig = "nohook resolv.conf";
        # If using NetworkManager:
        networkmanager.dns = "none";
      };

      services.dnscrypt-proxy2 = {
        enable = true;
        settings = {
          ipv6_servers = true;
          require_dnssec = true;

          sources.public-resolvers = {
            urls = [
              "https://raw.githubusercontent.com/DNSCrypt/dnscrypt-resolvers/master/v3/public-resolvers.md"
              "https://download.dnscrypt.info/resolvers-list/v3/public-resolvers.md"
            ];
            cache_file = "/var/lib/dnscrypt-proxy2/public-resolvers.md";
            minisign_key =
              "RWQf6LRCGA9i53mlYecO4IzT51TGPpvWucNSCh1CBM0QTaLn73Y7GFO3";
          };

          # You can choose a specific set of servers from https://github.com/DNSCrypt/dnscrypt-resolvers/blob/master/v3/public-resolvers.md
          # server_names = [ ... ];
        };
      };

      systemd.services.dnscrypt-proxy2.serviceConfig = {
        StateDirectory = "dnscrypt-proxy";
      };
    }

    # power management configs
    {
      environment.systemPackages =
        [ config.boot.kernelPackages.cpupower ac-connected ac-disconnected ];

      powerManagement.enable = false;
      services = {
        power-profiles-daemon.enable = false;

        # cpupower-gui.enable = true;

        tlp = {
          enable = true;
          settings = {
            NMI_WATCHDOG = 0;
            RADEON_DPM_PERF_LEVEL_ON_AC = "auto";
            RADEON_DPM_PERF_LEVEL_ON_BAT = "auto";
            # Check the output of tlp-stat -p to determine availability on your hardware
            # and additional profiles such as balanced-performance, quiet, cool.
            # PLATFORM_PROFILE_ON_AC = "balanced";
            # PLATFORM_PROFILE_ON_BAT = "balanced";

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

      services.udev.extraRules = mkIf (!config.services.tlp.enable) ''
        SUBSYSTEM=="power_supply", ATTR{online}=="1", RUN+="${ac-connected}/bin/ac-connected"
        SUBSYSTEM=="power_supply", ATTR{status}=="Discharging", RUN+="${ac-disconnected}/bin/ac-disconnected"
      '';

      boot = {
        kernelParams = [
          # "amd_pstate=passive"
          # "pcie_aspm=force"
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
          enable = true;
          settings = { Settings = { AutoConnect = true; }; };
        };
        networkmanager = {
          enable = true;
          wifi = {
            powersave = true;
            backend = mkForce "iwd";
          };

          settings = {
            device = {
              "wifi.scan-rand-mac-address" = "no";
            };
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
        udev.packages = with pkgs; [ gnome.gnome-settings-daemon ];
      };
      services.upower.enable = true;
      services.fprintd.enable = true;
    }
    # adhoc
    {
      environment.systemPackages = [
        pkgs.python3
        pkgs.taskwarrior
        pkgs.timewarrior
        pkgs.taskwarrior-tui
        pkgs.elixir_1_15

        pkgs.shellcheck
        pkgs.nodePackages.bash-language-server

        pkgs.zoom-us
        pkgs.slack
        pkgs.ngrok
        pkgs.dbeaver
        pkgs.teams-for-linux
        pkgs.dia
      ];

      services.postgresql = {
        enable = true;
        extraPlugins = with pkgs.postgresql.pkgs; [ timescaledb ];
        authentication = pkgs.lib.mkOverride 10 ''
          #type database  DBuser  auth-method
          local all       all     trust
          host  all       all     127.0.0.1       255.255.255.255     trust
        '';
        settings = {
          shared_preload_libraries = "timescaledb";
          log_statement = "all";
        };
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
      services.avahi.nssmdns4 = false;
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
        # sleep.extraConfig = ''
        #   HibernateDelaySec=30min
        # '';
      };

      # https://man.archlinux.org/man/systemd-sleep.conf.5
      # https://www.kernel.org/doc/html/latest/admin-guide/pm/sleep-states.html
      # Suspend mode -> Hybrid-Sleep. This enables hybrid-sleep then hibernate
      services = {
        # better timesync for unstable internet connections
        chrony = {
          enable = true;
          extraConfig = ''
            pool time.google.com       iburst minpoll 1 maxpoll 2 maxsources 3
            pool ntp.ubuntu.com        iburst minpoll 1 maxpoll 2 maxsources 3
            pool us.pool.ntp.org       iburst minpoll 1 maxpoll 2 maxsources 3

            maxupdateskew 5.0
            makestep 0.1 -1
          '';
        };

        timesyncd.enable = false;
        # iOS mounting
        usbmuxd.enable = false; # borken

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

    }

    {
      programs = {
        dconf.enable = true;
        iftop.enable = true;
        iotop.enable = true;
        nano.syntaxHighlight = true;
        zsh.enable = true;
      };

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
          ffmpeg_5-full
          firefox
          chromium
          microsoft-edge
          ghc
          libreoffice-fresh
          nixfmt-rfc-style

          config.boot.kernelPackages.bcc
        ];
        pathsToLink = [ "/share/zsh" ];
      };
    }

    {
      nixpkgs.config.allowUnfree = true;
      #virtualisation.virtualbox = { host.enable = true; };
      #users.extraGroups.vboxusers.members = [ "thongpv87" ];

      environment.systemPackages = with pkgs; [ podman-compose fake-docker-compose postman ];
      virtualisation = {
        podman = {
          enable = true;

          # Create a `docker` alias for podman, to use it as a drop-in replacement
          dockerCompat = true;

          # Required for containers under podman-compose to be able to talk to each other.
          defaultNetwork.settings.dns_enabled = true;
        };
      };
    }

    {
      nix.settings= {
        trusted-substituters = [ "https://nixcache.reflex-frp.org" "https://nix-node.cachix.org" ];
        trusted-public-keys = [ "ryantrinkle.com-1:JJiAKaRv9mWgpVAz8dwewnZe0AzzEAzPkagE9SP5NWI=" "nix-node.cachix.org-1:2YOHGtGxa8VrFiWAkYnYlcoQ0sSu+AqCniSfNagzm60=" ];
      };

      nix.registry."node".to = {
        type = "github";
        owner = "andyrichardson";
        repo = "nix-node";
      };

    }
  ]);
}
