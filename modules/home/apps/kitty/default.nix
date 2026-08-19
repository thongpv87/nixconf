{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.nixconf.apps.kitty;
  myshell = pkgs.writeShellScriptBin "myshell" ''
    #!/usr/bin/env sh
    ${pkgs.pywal}/bin/wal --theme tokyonight_storm &> /dev/null
    ${pkgs.nushell}/bin/nu $@
  '';
in
{
  options.nixconf.apps.kitty = {
    enable = mkOption { default = false; };
  };

  config = mkIf cfg.enable {
    home.packages = [
      pkgs.selected-nerdfonts
      myshell
    ];

    programs.kitty = {
      enable = true;
      settings = {
        font_family = "Monaspace Neon";
        bold_font = "Monaspace Neon Bold";
        italic_font = "Monaspace Neon Italic";
        bold_italic_font = "Monaspace Neon Bold Italic";
        font_size = "13.0";
        window_padding_width = "10 15";
        background_opacity = "1.0";
        
        # Rosepine dawn colors adapted from alacritty config
        foreground = "#575279";
        background = "#faf4ed";
        selection_foreground = "#575279";
        selection_background = "#dfdad9";
        cursor = "#cecacd";
        cursor_text_color = "#575279";
        
        color0 = "#f2e9e1";
        color8 = "#9893a5";
        color1 = "#b4637a";
        color9 = "#b4637a";
        color2 = "#286983";
        color10 = "#286983";
        color3 = "#ea9d34";
        color11 = "#ea9d34";
        color4 = "#56949f";
        color12 = "#56949f";
        color5 = "#907aa9";
        color13 = "#907aa9";
        color6 = "#d7827e";
        color14 = "#d7827e";
        color7 = "#575279";
        color15 = "#575279";
      };
      shellIntegration.enableZshIntegration = true;
    };
  };
}
