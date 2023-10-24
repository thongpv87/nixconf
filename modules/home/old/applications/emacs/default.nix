{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.nixconf.old.applications.emacs;
  doom = pkgs.writeShellScriptBin "doom" ''
    $HOME/.emacs.d/bin/doom $@
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
  options.nixconf.old.applications.emacs = {
    enable = mkOption { default = false; };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      sqlite
      ispell
      multimarkdown
      libgccjit
      ripgrep
      coreutils
      fd
      git
      doom
      tex
      mu
      isync
      gnutls

      python3Packages.pygments
      emacsPackages.pdf-tools
      selected-nerdfonts
    ];

    programs = {
      emacs = { enable = true; };
      offlineimap = { enable = true; };
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
