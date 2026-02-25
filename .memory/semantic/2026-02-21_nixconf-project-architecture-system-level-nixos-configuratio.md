---
id: sem-2026-02-21-24887e64
type: semantic
title: nixconf Project Architecture - System-level NixOS Configuration
date: '2026-02-21T14:01:06.366Z'
tags:
  - nixconf
  - architecture
  - system-modules
  - services
  - networking
  - nix
scope: architecture
---
## Project Structure Overview

The nixconf project is a NixOS configuration management system using Nix Flakes and a modular architecture.

### Directory Layout

**Root Level:**
- `/home/thongpv87/Code/nixconf/`
  - `flake.nix` - Main flake configuration (defines laptop and minimal nixosConfigurations)
  - `nixosProfiles/` - User-facing configuration profiles
  - `modules/` - Reusable NixOS modules (system, home, users, hardware)
  - `lib/` - Helper functions (makeHost.nix, makeUser.nix)
  - `overlays/` - Package overrides

### Module Structure

**System Modules** (System-level NixOS configs, NOT home-manager):
```
modules/system/
├── default.nix              # Main imports all sub-modules
├── boot/                    # Boot loader configuration (systemd-boot, grub)
├── core/                    # Core system packages and services (pipewire, chrony, fwupd)
├── networking/              # System networking (NetworkManager, iwd, encrypted-dns)
│   ├── default.nix          # Main networking config
│   └── encrypted-dns/       # dnscrypt-proxy2 with systemd.services definitions
├── laptop/                  # Laptop-specific configs
│   ├── default.nix          # ACPI, upower, bluetooth, logind settings
│   └── power-management/    # TLP or custom AC power handling via udev rules
├── services/                # System daemon services
│   ├── default.nix
│   ├── ios-support/         # usbmuxd service
│   └── virtualisation/      # Podman and VirtualBox configs
├── graphical/               # Display managers and WMs (Wayland, Xorg, Hyprland)
├── adhoc/                   # Ad-hoc packages (tailscale service, development tools)
└── apps/                    # System application configuration
```

**Home Modules** (User-level home-manager configs):
```
modules/home/
├── services/                # User services (systemd.user.services)
│   └── display-manager/hyprland/
├── core/
├── apps/
└── terminal/
```

### NixOS Profile System

**nixosProfiles/** - Configuration entrypoints that enable specific modules:

```
nixosProfiles/
├── laptop.nix               # Main laptop profile (imports most modules)
├── bootstrap.nix            # Minimal bootstrap profile
└── default.nix
```

**laptop.nix structure:**
```nix
{
  nixconf = {
    hardware.elitebook-845g10.enable = true;
    core.enable = true;
    laptop.enable = true;
    laptop.power-management.enable = true;
    networking.enable = true;
    networking.encrypted-dns.enable = false;
    services.enable = true;
    services.ios-support.enable = true;
    services.virtualisation = {...};
    graphical.enable = true;
    ...
  };
  # Also direct NixOS config
  networking.networkmanager.enable = true;
  networking.firewall = {...};
}
```

### How Modules Are Loaded

1. `flake.nix` defines nixosConfigurations.laptop
2. Uses `lib/makeHost.nix` which:
   - Imports `modules/system` and `modules/hardware`
   - Imports home-manager NixOS module
   - Merges in nixosProfiles (laptop.nix)
   - Enables openssh service
3. `modules/system/default.nix` imports all sub-modules:
   - Each sub-module (networking, laptop, services, etc.) uses `options.nixconf.*` pattern
   - Modules are conditionally enabled via nixosProfiles

### Networking Configuration Details

**File:** `/home/thongpv87/Code/nixconf/modules/system/networking/default.nix`
- Uses conditional enable via `config.nixconf.networking.enable`
- Configures:
  - `networking.wireless.iwd` - WiFi daemon
  - `networking.networkmanager` - NetworkManager with iwd backend, powersave enabled
  - WiFi MAC address randomization disabled (`wifi.scan-rand-mac-address = no`)

**File:** `/home/thongpv87/Code/nixconf/modules/system/networking/encrypted-dns/default.nix`
- Defines `systemd.services.dnscrypt-proxy2` - Example of system service definition
- Pattern: `systemd.services.<service-name>.serviceConfig = {...}`

### System Service Examples

**Pattern 1: Direct service config in module** (encrypted-dns):
```nix
systemd.services.dnscrypt-proxy2.serviceConfig = {
  StateDirectory = "dnscrypt-proxy";
};
```

**Pattern 2: Via services.<name> option** (core, laptop, adhoc):
```nix
services.usbmuxd.enable = true;
services.tailscale.enable = true;
services.tlp.enable = true;
services.acpid.enable = true;
```

**Pattern 3: Via udev rules for system-level triggers** (laptop):
```nix
services.udev.extraRules = ''
  SUBSYSTEM=="power_supply", ATTR{status}=="Discharging", ATTR{capacity}=="[0-5]", RUN+="${pkgs.systemd}/bin/systemctl suspend"
'';
```

### Where to Add WiFi Resume Service

**Recommended locations:**
1. **NEW MODULE**: Create `/home/thongpv87/Code/nixconf/modules/system/networking/wifi-resume/default.nix`
   - Follows existing pattern (networking sub-module)
   - Imports it in `modules/system/networking/default.nix`
   - Can define systemd service or udev rules

2. **EXISTING MODULE**: Add to `/home/thongpv87/Code/nixconf/modules/system/laptop/power-management/default.nix`
   - Already handles AC power events via udev
   - Could add WiFi reconnect logic here

3. **DIRECT**: Add to `/home/thongpv87/Code/nixconf/modules/system/adhoc/default.nix`
   - Already enables tailscale service
   - Quick location but less organized

**Service definition pattern to follow:**
```nix
systemd.services.wifi-resume = {
  description = "Resume WiFi connections after sleep";
  after = [ "network-online.target" ];
  wantedBy = [ "multi-user.target" ];
  serviceConfig = {
    Type = "oneshot";
    ExecStart = "/path/to/wifi-resume.sh";
    Restart = "on-failure";
  };
};
```

Or via udev (which is what laptop module uses for AC power events).
