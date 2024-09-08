{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.nixconf.terminal.tmux;
  shellCmd =
    if cfg.shell == "zsh" then
      "${pkgs.zsh}/bin/zsh"
    else if cfg.shell == "nu" then
      "${pkgs.nushell}/bin/nu"
    else
      "${pkgs.bashInteractive}/bin/bash";
in
{
  options.nixconf.terminal.tmux = {
    enable = mkOption {
      default = false;
      description = ''
        Whether to enable tmux module
      '';
    };

    shell = mkOption {
      type =
        with types;
        enum [
          "bash"
          "zsh"
          "nu"
        ];
      default = "zsh";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      home.packages = [
        pkgs.xsel
        pkgs.wl-clipboard
      ];
      programs.tmux = {
        enable = true;
        plugins = with pkgs.tmuxPlugins; [
          #resurrect
          sensible
          #yank
          prefix-highlight
          pain-control
          better-mouse-mode
          # THEMES

          {
            plugin = rose-pine;
            extraConfig = ''
              set -g @rose_pine_variant 'main'
              ${readFile ./rose-pine-theme.conf}
            '';
          }
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
    }
  ]);
}
