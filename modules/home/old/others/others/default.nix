{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.nixconf.old.others.others;

  alacritty-switch-theme = pkgs.writeShellScriptBin "alacritty-switch-theme" ''
    #!/usr/bin/env sh
    config_in="$XDG_CONFIG_HOME/alacritty/alacritty.yml.in"
    config="$XDG_CONFIG_HOME/alacritty/alacritty.yml"

    all=$(cat $HOME/.config/alacritty/alacritty.yml.in | grep "&" | awk -F ":" '{print $1}' | tr "\n" " ")
    if [ ! -f $config ]; then
        cat $config_in > $config
    else
        current=$(cat $config | grep "colors: \*" | awk -F "*" '{print $2}')
        next=$(echo $all | awk -F "$current" '{print $2}' | awk -F " " '{print $1}')
        if [ "$next" = "" ]; then
            next=$(echo $all | awk -F " " '{print $1}')
        fi
        echo "set alacritty theme: $next"
        sed -e "s/colors: \*monokai_pro/colors: *$next/" $config_in > $config
    fi'';
in
{
  options.nixconf.old.others.others = {
    enable = mkOption { default = false; };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      alacritty
      irssi
      alacritty-switch-theme
      gcolor3
      tree
      shotwell
      ranger
    ];

    home.file.".irssi" = {
      source = ./irssi;
      recursive = true;
    };
  };
}
