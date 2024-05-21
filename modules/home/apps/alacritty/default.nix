{ config, lib, pkgs, ... }:
with lib;
let cfg = config.nixconf.apps.rofi;
in {
  options.nixconf.apps.alacritty = { enable = mkOption { default = false; }; };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.selected-nerdfonts ];

    programs.alacritty = {
      enable = true;
      settings = {
        import = [ "/home/thongpv87/.cache/wal/colors-alacritty.toml" ];

        live_config_reload = true;
        window.opacity = 1;

        env = { TERM = "xterm-256color"; };

        font = {
          size = 14;

          bold = {
            family = "FiraCode Nerd Font Mono";
            style = "Bold";
          };

          italic = {
            family = "FiraCode Nerd Font Mono";
            style = "Retina";
          };

          normal = {
            family = "FiraCode Nerd Font Mono";
            style = "Medium";
          };
        };

        shell.program = "nu";

        window.padding = {
          x = 15;
          y = 10;
        };
      };
    };
  };
}
