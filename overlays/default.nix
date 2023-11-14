{ inputs }:
let inherit (inputs) nixvim hyprland;
in [
  #hyprland.overlays.default

  # native compile package
  (final: prev:
    let
      commonFlags = [ "-pipe" "-Wno-uninitialized" ];

      /* Example:

         { lib, clangStdenv, ... }:

         (lib.optimizeStdenv "armv9-a" clangStdenv).mkDerivation { ... }
      */
      optimizeStdenv = march:
        prev.stdenvAdapters.withCFlags (commonFlags ++ [ "-march=${march}" ]);

      /* Example:

         { lib, stdenv, ... }:

         (lib.optimizeStdenvWithNative stdenv).mkDerivation { ... }
      */
      optimizeStdenvWithNative = stdenv:
        prev.stdenvAdapters.impureUseNativeOptimizations
        (prev.stdenvAdapters.withCFlags commonFlags stdenv);
    in {
      lib = prev.lib.extend
        (_: _: { inherit optimizeStdenv optimizeStdenvWithNative; });
      optimizedV4Stdenv = final.lib.optimizeStdenv "x86-64-v4" prev.stdenv;
      optimizedZnver4Stdenv = final.lib.optimizeStdenv "znver4" prev.stdenv;
      optimizedNativeStdenv =
        prev.lib.warn "using native optimizations, forfeiting reproducibility"
        optimizeStdenvWithNative prev.stdenv;
      optimizedV4ClangStdenv =
        final.lib.optimizeStdenv "x86-64-v4" prev.llvmPackages_14.stdenv;
      optimizedZnver4ClangStdenv =
        final.lib.optimizeStdenv "znver4" prev.llvmPackages_14.stdenv;
      optimizedNativeClangStdenv =
        prev.lib.warn "using native optimizations, forfeiting reproducibility"
        optimizeStdenvWithNative prev.llvmPackages_14.stdenv;
    })

  #emacs-overlay.overlays.default
  (final: prev:
    let zen4pkg = pkg: pkg.override { stdenv = final.optimizedZnver4Stdenv; };
    in {
      lib = prev.lib // builtins;

      zen4KernelPackages = prev.linuxPackagesFor (prev.linux_testing.override {
        argsOverride = {
          stdenv = final.optimizedZnver4Stdenv;

          kernelPatches = [
            {
              name = "amd_pmf_freq_lock";
              patch = ./amd_pmf_freq_lock.patch;
            }
            {
              name = "amd_suspend_then_hibernate";
              patch = ./amd_suspend_then_hibernate.patch;
            }
            # {
            #   name = "amd_smart_pc";
            #   patch = ./Introduce-PMF-Smart-PC-Solution-Builder-Feature.patch;
            # }
          ];
        };
      });

      emacs29-pgtk = zen4pkg prev.emacs29-pgtk;
      alacritty = zen4pkg prev.alacritty;
      vlc = zen4pkg prev.vlc;

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
