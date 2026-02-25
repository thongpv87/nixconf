---
id: ep-2026-02-21-3256d173
type: episode
title: >-
  Explored nixconf project structure and identified WiFi resume service
  placement
date: '2026-02-21T14:01:21.037Z'
tags:
  - nixconf
  - exploration
  - system-services
  - networking
  - architecture-discovery
outcome: success
related_files:
  - /home/thongpv87/Code/nixconf/modules/system/networking/default.nix
  - >-
    /home/thongpv87/Code/nixconf/modules/system/networking/encrypted-dns/default.nix
  - >-
    /home/thongpv87/Code/nixconf/modules/system/laptop/power-management/default.nix
  - /home/thongpv87/Code/nixconf/modules/system/laptop/default.nix
  - /home/thongpv87/Code/nixconf/modules/system/adhoc/default.nix
  - /home/thongpv87/Code/nixconf/modules/system/core/default.nix
  - /home/thongpv87/Code/nixconf/flake.nix
related_memories: []
---
## Summary
Successfully completed a comprehensive read-only exploration of the nixconf NixOS configuration project to identify where system-level services (not home-manager) are defined and where a WiFi resume service should be added.

## What Was Done

### 1. Project Structure Discovery
- Identified main directories: modules/ (system, home, users, hardware), nixosProfiles/, lib/
- Found system-level NixOS configuration under modules/system/ (separate from home-manager)
- Located three types of module organization: boot, core, networking, laptop, services, graphical, adhoc, apps

### 2. Networking Configuration Files Found
- **Primary networking**: `/home/thongpv87/Code/nixconf/modules/system/networking/default.nix`
  - Enables NetworkManager with iwd backend
  - Enables wireless.iwd with AutoConnect enabled
  - Controls WiFi powersave mode
  
- **Encrypted DNS service example**: `/home/thongpv87/Code/nixconf/modules/system/networking/encrypted-dns/default.nix`
  - Shows systemd.services definition pattern: `systemd.services.dnscrypt-proxy2.serviceConfig`
  - Imports dynamically from networking/default.nix

### 3. System-level Service Patterns Identified
Found three patterns for defining system services:

**Pattern 1 - Direct systemd service definition:**
- Location: `/home/thongpv87/Code/nixconf/modules/system/networking/encrypted-dns/default.nix`
- Example: `systemd.services.dnscrypt-proxy2.serviceConfig = {...}`

**Pattern 2 - Via NixOS options (services.<name>):**
- Locations: `/home/thongpv87/Code/nixconf/modules/system/core/default.nix` (pipewire, chrony, fwupd)
- Locations: `/home/thongpv87/Code/nixconf/modules/system/services/ios-support/default.nix` (usbmuxd)
- Locations: `/home/thongpv87/Code/nixconf/modules/system/adhoc/default.nix` (tailscale)

**Pattern 3 - Via udev rules for power events:**
- Location: `/home/thongpv87/Code/nixconf/modules/system/laptop/power-management/default.nix`
- Uses `services.udev.extraRules` for AC power connect/disconnect triggers
- Uses systemctl commands via udev RUN+ actions

### 4. Key System Modules Analyzed
- **laptop/**: ACPI, upower, bluetooth, logind settings, power-management via TLP or udev
- **networking/**: NetworkManager, iwd WiFi daemon, optional encrypted DNS
- **services/**: ios-support (usbmuxd), virtualisation (podman, virtualbox)
- **core/**: pipewire audio, chrony NTP, fwupd firmware updates
- **adhoc/**: tailscale VPN service, development packages

### 5. Module Activation Pattern
- Each module in modules/system/ uses `options.nixconf.<name>` pattern for conditional enabling
- Activation happens via nixosProfiles/laptop.nix which sets `nixconf.<module>.enable = true`
- System profile is loaded by lib/makeHost.nix and merged into NixOS configuration

## Recommended Locations for WiFi Resume Service

**Option 1 (Best): Create new dedicated module**
- Path: `/home/thongpv87/Code/nixconf/modules/system/networking/wifi-resume/default.nix`
- Rationale: Follows existing networking sub-module pattern, isolated responsibility

**Option 2 (Good): Extend power-management module**
- Path: `/home/thongpv87/Code/nixconf/modules/system/laptop/power-management/default.nix`
- Rationale: Already handles post-sleep power events, natural fit for WiFi reconnect

**Option 3 (Quick): Add to adhoc module**
- Path: `/home/thongpv87/Code/nixconf/modules/system/adhoc/default.nix`
- Rationale: Existing service definitions here (tailscale), quick but less organized

## Service Definition Pattern to Follow

For systemd service:
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

For udev rule (fits power-management pattern):
```nix
services.udev.extraRules = ''
  SUBSYSTEM=="power_supply", ATTR{online}=="1", RUN+="${pkgs.systemd}/bin/systemctl restart network-manager"
'';
```

## File Paths for Reference
- System default import: `/home/thongpv87/Code/nixconf/modules/system/default.nix`
- Networking main: `/home/thongpv87/Code/nixconf/modules/system/networking/default.nix`
- Encrypted DNS service example: `/home/thongpv87/Code/nixconf/modules/system/networking/encrypted-dns/default.nix`
- Power management with udev: `/home/thongpv87/Code/nixconf/modules/system/laptop/power-management/default.nix`
- Laptop config: `/home/thongpv87/Code/nixconf/modules/system/laptop/default.nix`
- Flake entry point: `/home/thongpv87/Code/nixconf/flake.nix`
- Host builder: `/home/thongpv87/Code/nixconf/lib/makeHost.nix`
- Profile: `/home/thongpv87/Code/nixconf/nixosProfiles/laptop.nix`

## What Failed / Lessons
None - all file reads successful. Project is well-organized and follows consistent patterns.
