{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.nixconf.old.terminal.tmux;
  shellCmd = if cfg.shell == "zsh" then
    "${pkgs.zsh}/bin/zsh"
  else if cfg.shell == "nu" then
    "${pkgs.nushell}/bin/nu"
  else
    "${pkgs.bashInteractive}/bin/bash";
in {
  options.nixconf.old.terminal.tmux = {
    enable = mkOption {
      default = false;
      description = ''
        Whether to enable tmux module
      '';
    };

    shell = mkOption {
      type = with types; enum [ "bash" "zsh" "nu" ];
      default = "zsh";
    };
  };

  config = mkIf cfg.enable (mkMerge [{
    home.packages = [ pkgs.xsel ];
    programs.tmux = {
      enable = true;
      plugins = with pkgs.tmuxPlugins; [
        #resurrect
        sensible
        #yank
        prefix-highlight
        pain-control
        better-mouse-mode
        # {
        #   plugin = net-speed;
        #   extraConfig = "${readFile ./needspeed.conf}";
        # }
        # {
        #   plugin = mode-indicator;
        #   extraConfig = "${readFile ./mode-indicator.conf}";
        # }
        # THEMES
        {
          plugin = rose-pine;
          extraConfig = ''
            set -g @rose_pine_variant 'main'
            ${readFile ./rose-pine-theme.conf}
          '';
        }
        # {
        #   plugin = power-theme;
        #   extraConfig = "set -g @tmux_power_theme 'default'";
        # }
      ];
      baseIndex = 1;
      shortcut = "o";
      customPaneNavigationAndResize = true;
      keyMode = "vi";
      newSession = true;
      secureSocket = false;
      terminal = "xterm-256color";

      extraConfig = ''
        set-option  -g default-shell ${shellCmd}
        # xorg copy
        # set -s copy-command 'xsel -ib'
        # wayland copy
        set -g @override_copy_command 'wl-copy'
        ${readFile ./bindings.conf}
        ${readFile ./tmux.conf}
      '';
    };
  }]);
}
