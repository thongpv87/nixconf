#!/usr/bin/env python3
import os
import glob
import json
import shutil

def fetch_apps():
    apps = {}
    home = os.path.expanduser('~')
    user = os.environ.get('USER', 'thongpv87')

    # Detect preferred terminal emulator for Terminal=true apps
    term_bin = "kitty"
    if not shutil.which("kitty"):
        if shutil.which("alacritty"):
            term_bin = "alacritty"
        elif shutil.which("ghostty"):
            term_bin = "ghostty"
        elif shutil.which("foot"):
            term_bin = "foot"

    # Base directories + dynamic XDG_DATA_DIRS for NixOS & Home Manager
    dirs = set([
        '/usr/share/applications',
        '/usr/local/share/applications',
        f'{home}/.local/share/applications',
        '/var/lib/flatpak/exports/share/applications',
        f'{home}/.local/share/flatpak/exports/share/applications',
        f'{home}/.nix-profile/share/applications',
        f'/etc/profiles/per-user/{user}/share/applications',
        '/run/current-system/sw/share/applications'
    ])

    xdg_dirs = os.environ.get('XDG_DATA_DIRS', '').split(':')
    for xd in xdg_dirs:
        if xd:
            app_dir = os.path.join(xd, 'applications')
            dirs.add(app_dir)

    for d in dirs:
        if not os.path.exists(d):
            continue

        for f in glob.glob(os.path.join(d, '**/*.desktop'), recursive=True):
            try:
                with open(f, 'r', encoding='utf-8', errors='ignore') as file:
                    app = {'name': '', 'exec': '', 'icon': ''}
                    is_desktop = False
                    no_display = False
                    is_terminal = False

                    for line in file:
                        line = line.strip()
                        if line == '[Desktop Entry]':
                            is_desktop = True
                        elif line.startswith('['):
                            is_desktop = False

                        if is_desktop:
                            if line.startswith('Name=') and not app['name']:
                                app['name'] = line[5:]
                            elif line.startswith('Exec=') and not app['exec']:
                                raw_exec = line[5:].split(' %')[0].split(' @@')[0]
                                app['exec'] = raw_exec
                            elif line.startswith('Icon=') and not app['icon']:
                                app['icon'] = line[5:]
                            elif line.startswith('NoDisplay=true') or line.startswith('NoDisplay=1'):
                                no_display = True
                            elif line.startswith('Terminal=true') or line.startswith('Terminal=1'):
                                is_terminal = True

                    if app['name'] and app['exec'] and not no_display:
                        if is_terminal and not app['exec'].startswith(term_bin):
                            app['exec'] = f"{term_bin} -e {app['exec']}"
                        # Clean up wrapper names for cleaner search
                        clean_name = app['name']
                        if clean_name == "Neovim wrapper":
                            clean_name = "Neovim"
                        apps[clean_name] = app
            except Exception:
                pass

    # Sort alphabetically and return as JSON
    res = list(apps.values())
    res.sort(key=lambda x: x['name'].lower())
    print(json.dumps(res))

if __name__ == "__main__":
    fetch_apps()
