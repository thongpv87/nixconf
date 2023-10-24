{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.nixconf.old.terminal;
  shellCmd = if cfg.shell == "zsh" then
    "${pkgs.zsh}/bin/zsh"
  else if cfg.shell == "bash" then
    "${pkgs.bashInteractive}/bin/bash"
  else # if cfg.shell == "fish"
    "${pkgs.fish}/bin/fish";
  aliases = {
    ssh = "TERM=xterm-256color ssh";
    irssi = "TERM=xterm-256color irssi";
    em = "emacsclient -t";
    vi = "nvim";
  };

in {
  imports = [ ./tmux ];

  options.nixconf.old.terminal = { enable = mkOption { default = false; }; };

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
        shellAliases = aliases;
        initExtra = ''
          # enable vim navigation
          set -o vi
          eval "$(starship init bash)"
        '';
      };

      fzf = {
        enable = true;
        enableBashIntegration = true;
        enableZshIntegration = true;
        enableFishIntegration = true;
        fileWidgetOptions = [ "--preview 'head {}'" ];
      };

      direnv = {
        enable = true;
        nix-direnv = { enable = true; };
        enableZshIntegration = true;
      };
    };

    xdg = {
      enable = true;
      configFile."starship.toml".source = ./starship.toml;
    };

  };
}
