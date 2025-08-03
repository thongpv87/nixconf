{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.nixconf.apps.rofi;
  myshell = pkgs.writeShellScriptBin "myshell" ''
    #!/usr/bin/env sh
    ${pkgs.pywal}/bin/wal --theme tokyonight_storm &> /dev/null
    ${pkgs.nushell}/bin/nu $@
  '';
  themes = {
    tokyonight_night = import ./tokyonight_night_theme.nix;
    tokyonight_storm = import ./tokyonight_storm_theme.nix;
    tokyonight_moody = import ./tokyonight_moody_theme.nix;
    rosepine_dawn = import ./rosepine_dawn.nix;
  };
in
{
  options.nixconf.apps.alacritty = {
    enable = mkOption { default = false; };
  };

  config = mkIf cfg.enable {
    home.packages = [
      pkgs.selected-nerdfonts
      myshell
    ];

    programs.alacritty = {
      enable = true;
      settings = {
        # import = [ "/home/thongpv87/.cache/wal/colors-alacritty.toml" ];

        general = {
          live_config_reload = true;
        };

        window = {
          opacity = 1;
          decorations_theme_variant = "Dark";
        };

        env = {
          TERM = "xterm-256color";
        };

        terminal.shell = {
          program = "nu";
        };

        font = {
          size = 15;

          bold = {
            family = "RobotoMono Nerd Font Propo";
            style = "Bold";
          };

          italic = {
            family = "RobotoMono Nerd Font Propo";
            style = "Medium Italic";
          };

          normal = {
            family = "RobotoMono Nerd Font Propo";
            style = "Medium";
          };

          bold_italic = {
            family = "RobotoMono Nerd Font Propo";
            style = "Bold Italic";
          };
        };

        window.padding = {
          x = 15;
          y = 10;
        };
      }
      // themes.rosepine_dawn;
    };
  };
}
