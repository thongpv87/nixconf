{ inputs }:
let inherit (inputs) nixvim emacs-overlay nbfc-linux;
in [

  #emacs-overlay.overlays.default
  (final: prev: {
    lib = prev.lib // builtins;
    bamboo = prev.ibus-engines.bamboo.overrideAttrs (oldAttrs: {
      version = "v0.8.1";
      src = prev.fetchFromGitHub {
        owner = "BambooEngine";
        repo = "ibus-bamboo";
        rev = "c0001c571d861298beb99463ef63816b17203791";
        sha256 = "sha256-7qU3ieoRPfv50qM703hEw+LTSrhrzwyzCvP9TOLTiDs=";
      };
      buildInputs = oldAttrs.buildInputs ++ [ prev.glib prev.gtk3 ];
    });

    selected-nerdfonts = prev.nerdfonts.override {
      fonts = [
        "FiraCode"
        "FiraMono"
        "SourceCodePro"
        "DejaVuSansMono"
        "DroidSansMono"
        "Inconsolata"
        "Iosevka"
        "RobotoMono"
        "JetBrainsMono"
        "Terminus"
      ];
      enableWindowsFonts = false;
    };

    # vim = nixvim.legacyPackages.${prev.system}.makeNixvim {
    #   plugins = {
    #     telescope.enable = true;
    #     # none-ls.enable = true;
    #     # none-ls.sources.formatting.alejandra.enable = true;
    #     nix.enable = true;
    #     gitsigns.enable = true;
    #     fugitive.enable = true;
    #     lsp = {
    #       enable = true;
    #       servers.nil_ls.enable = true;
    #     };
    #     treesitter.enable = true;
    #     lightline.enable = true;
    #   };
    #   colorschemes.base16 = {
    #     enable = true;
    #     useTruecolor = true;
    #     colorscheme = "solarized-dark";
    #   };
    #   options = {
    #     number = true; # Show line numbers
    #     relativenumber = true; # Show relative line numbers
    #     shiftwidth = 2; # Tab width should be 2
    #   };
    # };
  })
]
