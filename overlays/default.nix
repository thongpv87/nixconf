{ inputs }:
let
  inherit (inputs)
    # hyprland
    # hyprpanel
    # hyprpaper
    ;
in
[
  #hyprland.overlays.default
  # hyprpaper.overlays.default
  # hyprpanel.overlay

  # native compile package
  (
    final: prev:
    let
      commonFlags = [
        "-pipe"
        "-Wno-uninitialized"
      ];

      /*
        Example:

        { lib, clangStdenv, ... }:

        (lib.optimizeStdenv "armv9-a" clangStdenv).mkDerivation { ... }
      */
      optimizeStdenv = march: prev.stdenvAdapters.withCFlags (commonFlags ++ [ "-march=${march}" ]);

      /*
        Example:

        { lib, stdenv, ... }:

        (lib.optimizeStdenvWithNative stdenv).mkDerivation { ... }
      */
      optimizeStdenvWithNative =
        stdenv:
        prev.stdenvAdapters.impureUseNativeOptimizations (
          prev.stdenvAdapters.withCFlags commonFlags stdenv
        );
    in
    {
      lib = prev.lib.extend (_: _: { inherit optimizeStdenv optimizeStdenvWithNative; });
      optimizedV4Stdenv = final.lib.optimizeStdenv "x86-64-v4" prev.stdenv;
      optimizedZnver4Stdenv = final.lib.optimizeStdenv "znver4" prev.stdenv;
      optimizedNativeStdenv =
        prev.lib.warn "using native optimizations, forfeiting reproducibility" optimizeStdenvWithNative
          prev.stdenv;
      optimizedV4ClangStdenv = final.lib.optimizeStdenv "x86-64-v4" prev.llvmPackages_14.stdenv;
      optimizedZnver4ClangStdenv = final.lib.optimizeStdenv "znver4" prev.llvmPackages_14.stdenv;
      optimizedNativeClangStdenv =
        prev.lib.warn "using native optimizations, forfeiting reproducibility" optimizeStdenvWithNative
          prev.llvmPackages_14.stdenv;
    }
  )

  #emacs-overlay.overlays.default
  (
    final: prev:
    let
      zen4pkg = pkg: pkg.override { stdenv = final.optimizedZnver4Stdenv; };
    in
    {
      # lib = prev.lib // builtins;

      zen4KernelPackages = prev.linuxPackagesFor (
        prev.linux_testing.override {
          argsOverride = {
            stdenv = final.optimizedZnver4Stdenv;
          };
        }
      );

      #emacs29-pgtk = zen4pkg prev.emacs29-pgtk;

      bamboo = prev.ibus-engines.bamboo.overrideAttrs (oldAttrs: {
        version = "v0.8.1";
        src = prev.fetchFromGitHub {
          owner = "BambooEngine";
          repo = "ibus-bamboo";
          rev = "c0001c571d861298beb99463ef63816b17203791";
          sha256 = "sha256-7qU3ieoRPfv50qM703hEw+LTSrhrzwyzCvP9TOLTiDs=";
        };
        buildInputs = oldAttrs.buildInputs ++ [
          prev.glib
          prev.gtk3
        ];
      });

      discord = prev.discord.overrideAttrs (e: rec {
        desktopItem = e.desktopItem.override (d: {
          exec = "${d.exec} --enable-wayland-ime";
        });

        # Update the install script to use the new .desktop entry
        installPhase = builtins.replaceStrings [ "${e.desktopItem}" ] [ "${desktopItem}" ] e.installPhase;
      });

      chromium = prev.chromium.override { commandLineArgs = "--gtk-version=4"; };

      selected-nerdfonts = prev.buildEnv {
        name = "myutils";
        paths = with prev.nerd-fonts; [
          fira-code
          fira-mono
          sauce-code-pro
          dejavu-sans-mono
          droid-sans-mono
          inconsolata
          iosevka
          roboto-mono
          jetbrains-mono
          victor-mono
        ];
      };
      # nixvim = nixvim.legacyPackages.x86_64-linux.makeNixvimWithModule {
      #   pkgs = prev;
      #   module = import ./nixvim;
      # };
    }
  )
]
