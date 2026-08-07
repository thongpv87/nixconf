{ config, pkgs, lib, ... }:
let
  cfg = config.nixconf.services.display-manager.hyprland;
in
lib.mkIf (cfg.enable && !cfg.useIlyamiroConfig) {
  nixconf = {
    services.display-manager.hyprland = {
      waybar.enable = lib.mkDefault true;
    };
  };

  services.hyprpaper = {
    enable = true;
    settings = {
      wallpaper =
        let
          pic = "countryside_landscape.jpg";
        in
        builtins.map (m: {
          monitor = m;
          path = "${./../wallpapers}/${pic}";
        }) [ "DP-1" "DP-2" "eDP-1" ];
    };
  };

  systemd.user.services.dunst = {
    Unit = {
      Description = "Dunst notification daemon";
      After = [ "hm-graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "dbus";
      BusName = "org.freedesktop.Notifications";
      ExecStart = "${pkgs.dunst}/bin/dunst";
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };

  wayland.windowManager.hyprland.settings = {
    source = [ "/home/thongpv87/.cache/wal/colors-hyprland.conf" ];
    animations = import ./../animations/${cfg.animation}.nix;
    general = import ./../windows/${cfg.window}.nix;
    bind = [
      "$mod, P, exec, rofi -show drun -replace -i -show-icons"
      "$mod, V, exec, ${pkgs.cliphist}/bin/cliphist list | rofi -dmenu -p clipboard -i | ${pkgs.cliphist}/bin/cliphist decode | ${pkgs.wl-clipboard}/bin/wl-copy && sleep 0.1 && ${pkgs.wtype}/bin/wtype -M shift -k insert -m shift"
    ];
  };
}
