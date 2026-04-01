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

      claude-code =
        let
          version = "2.1.89";
          src = prev.fetchzip {
            url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
            hash = "sha256-FoTm6KDr+8Dzhk4ibZUlU1QLPFdPm/OriUUWqAaFswg=";
          };
        in
        prev.stdenv.mkDerivation {
          pname = "claude-code";
          inherit version src;

          nativeBuildInputs = [ prev.makeWrapper ];

          dontBuild = true;

          # Cache fix patch: preserve deferred_tools_delta and mcp_instructions_delta
          # attachments in session JSONL so prompt caching works on resumed sessions.
          # See: https://github.com/Rangizingo/cc-cache-fix
          postPatch = ''
            substituteInPlace cli.js \
              --replace-fail \
                'if(q.attachment.type==="hook_deferred_tool")return!0;return!1}' \
                'if(q.attachment.type==="hook_deferred_tool")return!0;if(q.attachment.type==="deferred_tools_delta")return!0;if(q.attachment.type==="mcp_instructions_delta")return!0;return!1}'
          '';

          installPhase = ''
            runHook preInstall

            mkdir -p $out/lib/claude-code $out/bin
            cp -r . $out/lib/claude-code/

            makeWrapper ${prev.nodejs}/bin/node $out/bin/claude \
              --add-flags "$out/lib/claude-code/cli.js" \
              --set DISABLE_AUTOUPDATER 1 \
              --set DISABLE_INSTALLATION_CHECKS 1 \
              --prefix PATH : ${
                prev.lib.makeBinPath [
                  prev.procps
                  prev.bubblewrap
                  prev.socat
                ]
              }

            runHook postInstall
          '';

          meta = {
            description = "Claude Code with prompt cache fix";
            mainProgram = "claude";
          };
        };

      google-gemini = prev.writeShellScriptBin "gemini" ''
        exec ${prev.nodejs}/bin/npx @google/gemini-cli@latest "$@"
      '';
    }
  )
]
