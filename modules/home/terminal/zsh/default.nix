{
  pkgs,
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.nixconf.terminal.zsh;
in
{
  # Interesting configs:
  # https://vermaden.wordpress.com/2021/09/19/ghost-in-the-shell-part-7-zsh-setup/

  options.nixconf.terminal.zsh = {
    enable = mkOption {
      description = "Enable zsh with settings";
      type = types.bool;
      default = false;
    };
  };

  config = mkIf (cfg.enable) (
    let
      # Remove home directory from xdg
      dotDir = builtins.substring (
        (builtins.stringLength config.home.homeDirectory) + 1
      ) (builtins.stringLength config.xdg.configHome) config.xdg.configHome;
    in
    {
      home.packages = with pkgs; [ any-nix-shell ];
      programs = {
        starship.enableNushellIntegration = true;
        direnv.enableNushellIntegration = true;
        atuin.enableNushellIntegration = true;

        zsh = {
          enable = true;
          autosuggestion = {
            enable = true;
            #strategy = ["history" "completion"];
            #highlightStyle = "fg=cyan";
          };

          historySubstringSearch.enable = true;
          syntaxHighlighting.enable = true;
          enableCompletion = true;

          shellAliases = {
            ssh = "TERM=xterm-256color ssh";
            irssi = "TERM=xterm-256color irssi";
            em = "emacsclient -t";
            vi = "nvim";
            vim = "nvim";
          };

          completionInit = ''
            autoload -U compinit
            # https://unix.stackexchange.com/questions/214657/what-does-zstyle-do
            zstyle ":completion:*" menu select
            # case insensitive
            zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
            zmodload zsh/complist
            compinit
            _comp_options+=(globdots) # enable hidden files

            # Use vim keys in tab complete menu
            bindkey -M menuselect 'h' vi-backward-char
            bindkey -M menuselect 'k' vi-up-line-or-history
            bindkey -M menuselect 'l' vi-forward-char
            bindkey -M menuselect 'j' vi-down-line-or-history
            bindkey -v '^?' backward-delete-char
          '';
          autocd = true;
          dotDir = "${dotDir}/zsh";
          history = {
            extended = true;
            ignoreDups = true;
            ignoreSpace = true;
            save = 100000;
            size = 100000;
            share = true;
            path = "${config.xdg.dataHome}/zsh/zsh_history";
          };
          localVariables = {
            ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE = "fg=8,bold";
          };

          initExtraFirst = "";
          initExtraBeforeCompInit = "";
          initContent = ''
            # OSC-7 Escape Sequence
            # https://codeberg.org/dnkl/foot/wiki#spawning-new-terminal-instances-in-the-current-working-directory
            function osc7 {
                local LC_ALL=C
                export LC_ALL

                setopt localoptions extendedglob
                input=( ''${(s::)PWD} )
                uri=''${(j::)input/(#b)([^A-Za-z0-9_.\!~*\'\(\)-\/])/%''${(l:2::0:)$(([##16]#match))}}
                print -n "\e]7;file://''${HOSTNAME}''${uri}\e\\"
            }
            add-zsh-hook -Uz chpwd osc7

            # OSC-133, jump between prompts
            # https://codeberg.org/dnkl/foot/wiki#jumping-between-prompts
            precmd() {
                print -Pn "\e]133;A\e\\"
            }

            # Edit line in vim with ctrl-e:
            autoload edit-command-line; zle -N edit-command-line
            bindkey '^e' edit-command-line

            # https://unix.stackexchange.com/questions/433273/changing-cursor-style-based-on-mode-in-both-zsh-and-vim
            # vi mode
            bindkey -v
            export KEYTIMEOUT=1

            function zle-keymap-select {
              if [[ ''${KEYMAP} == vicmd ]] ||
                 [[ $1 = 'block' ]]; then
                echo -ne '\e[2 q'
              elif [[ ''${KEYMAP} == main ]] ||
                   [[ ''${KEYMAP} == viins ]] ||
                   [[ ''${KEYMAP} = "" ]] ||
                   [[ $1 = 'beam' ]]; then
                echo -ne '\e[5 q'
              fi
            }
            zle -N zle-keymap-select
            zle-line-init() {
              zle -K viins
              echo -ne '\e[6 q'
            }
            zle -N zle-line-init
            echo -ne '\e[6 q' # use beam shape cursor on startup
            preexec() { echo -ne '\e[6 q' ;} # use beam shape cursor for each new prompt

            # Disable less(1) history
            export LESSHISTSIZE=0

            # theme.sh
            if command -v theme.sh > /dev/null; then
              [ -e ~/.theme_history ] && theme.sh "$(theme.sh -l|tail -n1)"
            fi
            # any-nix-shell
            any-nix-shell zsh --info-right | source /dev/stdin
            export DIRENV_LOG_FORMAT=
          ''; # addd to .zshrc
          profileExtra = ''
            function haskell-env() {
             pkgs=$@
             echo "Starting haskell shell, pkgs = $pkgs"
             nix-shell -p "haskellPackages.ghcWithPackages (pkgs: with pkgs; [$pkgs])"
            }
          ''; # profiles to add to .zprofile

          "oh-my-zsh" = {
            enable = true;
            plugins = [
              "git"
              "sudo"
              "gitignore"
              "cp"
              "safe-paste"
            ];
          };
        };
      };
    }
  );
}
