{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.nixconf.terminal;
in
{
  imports = [
    ./tmux
    ./zsh
    ./nushell
  ];

  options.nixconf.terminal = {
    enable = mkOption {
      description = "Enable terminal configs";
      type = types.bool;
      default = false;
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      starship
      selected-nerdfonts
      theme-sh
      bash-completion
    ];

    programs = {
      bash = {
        enable = true;
        historyControl = [ "ignoredups" ];
        shellAliases = {
          ssh = "TERM=xterm-256color ssh";
          irssi = "TERM=xterm-256color irssi";
          em = "emacsclient -t";
          vi = "nvim";
          vim = "nvim";
        };

        initContent = ''
          # enable vim navigation
          set -o vi
        '';
      };

      fzf = {
        enable = true;
        fileWidgetOptions = [ "--preview 'head {}'" ];
      };

      direnv = {
        enable = true;
        nix-direnv = {
          enable = true;
        };
        enableBashIntegration = true;
      };

      starship = {
        enable = true;
        enableBashIntegration = true;
      };

      thefuck = {
        enable = true;
        enableBashIntegration = true;
      };

      atuin = {
        enable = true;
        enableBashIntegration = true;

        settings = {
          keymap_mode = "vim-insert";
          filter_mode = "global";
          workspaces = true;
          exit_mode = "return-query";
          enter_accept = false;
        };
      };
    };
  };
}
