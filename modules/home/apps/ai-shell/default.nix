{
  pkgs,
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.nixconf.apps.ai-shell;
  ai-shell-pkg = pkgs.writers.writePython3Bin "ai-shell" {
    libraries = [ ];
  } (builtins.readFile ./ai-shell.py);
in
{
  options.nixconf.apps.ai-shell = {
    enable = mkEnableOption "ai-shell completion";
    providersFile = mkOption {
      description = "Path to a JSON file containing AI providers";
      type = types.nullOr types.str;
      default = null;
    };
    providers = mkOption {
      description = "List of AI providers for shell completion";
      type = types.listOf (types.submodule {
        options = {
          name = mkOption { type = types.str; example = "openai"; };
          url = mkOption {
            type = types.str;
            default = "https://api.openai.com/v1/chat/completions";
          };
          key = mkOption { type = types.str; };
          model = mkOption {
            type = types.str;
            default = "gpt-3.5-turbo";
          };
        };
      });
      default = [ ];
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ ai-shell-pkg ];

    # We set the environment variable in the session
    home.sessionVariables = {
      AI_PROVIDERS_JSON = builtins.toJSON cfg.providers;
      AI_PROVIDERS_FILE = cfg.providersFile;
    };

    # Zsh integration
    programs.zsh.initExtra = mkAfter ''
      # AI Shell Completion (Ctrl-x, Ctrl-a)
      _ai_shell_completion() {
        local completion
        completion=$(ai-shell "$BUFFER" 2>/dev/null)
        if [ $? -eq 0 ] && [ -n "$completion" ]; then
          BUFFER="$completion"
          CURSOR=$#BUFFER
        fi
        zle redisplay
      }
      zle -N _ai_shell_completion
      bindkey '^x^a' _ai_shell_completion
    '';

    # Nushell integration
    programs.nushell.extraConfig = mkAfter ''
      # AI Shell Completion (Ctrl-Alt-a)
      $env.config = ($env.config | upsert keybindings ($env.config.keybindings | append {
        name: ai_completion
        modifier: control_alt
        keycode: char_a
        mode: [vi_insert, vi_normal]
        event: {
          send: executehostcommand
          cmd: "commandline edit --insert (ai-shell (commandline) | str trim)"
        }
      }))
    '';

    # Bash integration
    programs.bash.initExtra = mkAfter ''
      # AI Shell Completion (Ctrl-x, Ctrl-a)
      _bash_ai_completion() {
        local completion
        completion=$(ai-shell "$READLINE_LINE" 2>/dev/null)
        if [ $? -eq 0 ] && [ -n "$completion" ]; then
          READLINE_LINE="$completion"
          READLINE_POINT=''${#READLINE_LINE}
        fi
      }
      bind -x '"\C-x\C-a": _bash_ai_completion'
    '';
  };
}
