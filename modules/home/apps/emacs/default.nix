{ config, pkgs, lib, ... }:
with lib;
let
  cfg = config.nixconf.apps.emacs;
  inherit (lib)
    mkOption mkMerge mkIf mkDefault mkForce types mdDoc mkEnableOption;
  doom = pkgs.writeShellScriptBin "doom" ''
    $HOME/.config/emacs/bin/doom $@
  '';

  tex = (pkgs.texlive.combine {
    inherit (pkgs.texlive)
      scheme-full dvisvgm dvipng # for preview and export as html
      pygmentex minted hyperref wrapfig amsmath capt-of ulem vntex babel fvextra
      mdframed efbox latex-bin latexmk polyglossia tcolorbox;
    #(setq org-latex-compiler "lualatex")
    #(setq org-preview-latex-default-process 'dvisvgm)
  });
in {
  options.nixconf.apps.emacs = {
    enable = mkOption {
      description = "Enable a set of common applications";
      type = types.bool;
      default = false;
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      sqlite
      ispell
      multimarkdown
      libgccjit
      ripgrep
      coreutils
      wordnet
      fd
      git
      doom
      #tex
      mu
      isync
      gnutls

      python3Packages.pygments
      emacsPackages.pdf-tools
      selected-nerdfonts
    ];

    programs.emacs = {
      enable = true;
      package = pkgs.emacs29-pgtk;
    };
    xdg.configFile."doom" = {
      source = ./doom.d;
      recursive = true;
    };

    services = {
      emacs = {
        enable = true;
        socketActivation.enable = true;
        client.enable = true;
      };
    };
  };
}
