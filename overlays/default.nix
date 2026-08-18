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

      antigravity-ide =
        let
          anti-power-src = prev.fetchFromGitHub {
            owner = "daoif";
            repo = "anti-power";
            rev = "master";
            hash = "sha256-TGaKxWKxkATflXF/za3cCcO0FRPN8v47CkluZ5lrwHU=";
          };
          customVersion = if builtins.pathExists ./antigravity-version.json
            then builtins.fromJSON (builtins.readFile ./antigravity-version.json)
            else null;
          basePkg = if customVersion != null then
            prev.antigravity-ide.overrideAttrs (old: {
              version = customVersion.version;
              src = prev.fetchurl {
                url = customVersion.url;
                sha256 = customVersion.sha256;
              };
              sourceRoot = null;
            })
          else prev.antigravity-ide;
        in
        basePkg.overrideAttrs (oldAttrs: {
          postInstall =
            (oldAttrs.postInstall or "")
            + ''
              echo "Applying anti-power patch to antigravity-ide..."
              APP_DIR="$out/lib/antigravity-ide/resources/app"
              PATCH_DIR="${anti-power-src}/patcher/patches"

              if [ -d "$APP_DIR/extensions/antigravity" ]; then
                cp -f "$PATCH_DIR/cascade-panel.html" "$APP_DIR/extensions/antigravity/cascade-panel.html"
                rm -rf "$APP_DIR/extensions/antigravity/cascade-panel"
                cp -r "$PATCH_DIR/cascade-panel" "$APP_DIR/extensions/antigravity/cascade-panel"
              fi

              WORKBENCH_DIR="$APP_DIR/out/vs/code/electron-browser/workbench"
              if [ -d "$WORKBENCH_DIR" ]; then
                cp -f "$PATCH_DIR/workbench.html" "$WORKBENCH_DIR/workbench.html"
                rm -rf "$WORKBENCH_DIR/sidebar-panel"
                cp -r "$PATCH_DIR/sidebar-panel" "$WORKBENCH_DIR/sidebar-panel"

                cp -f "$PATCH_DIR/workbench-jetski-agent.html" "$WORKBENCH_DIR/workbench-jetski-agent.html"
                rm -rf "$WORKBENCH_DIR/manager-panel"
                cp -r "$PATCH_DIR/manager-panel" "$WORKBENCH_DIR/manager-panel"
              fi
            '';
        });

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
          version = "2.1.100";
          src = prev.fetchzip {
            url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
            hash = "sha256-7/Rhk1z3Us2vOYGa85lkVIzzqdQFmfmAxrT39a7D27Y=";
          };
        in
        prev.stdenv.mkDerivation {
          pname = "claude-code";
          inherit version src;

          nativeBuildInputs = [ prev.makeWrapper ];

          dontBuild = true;

          # # Cache fix patch: preserve deferred_tools_delta and mcp_instructions_delta
          # # attachments in session JSONL so prompt caching works on resumed sessions.
          # # See: https://github.com/Rangizingo/cc-cache-fix
          # postPatch = ''
          #   substituteInPlace cli.js \
          #     --replace-fail \
          #       'if(q.attachment.type==="hook_deferred_tool")return!0;return!1}' \
          #       'if(q.attachment.type==="hook_deferred_tool")return!0;if(q.attachment.type==="deferred_tools_delta")return!0;if(q.attachment.type==="mcp_instructions_delta")return!0;return!1}'
          # '';

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

      antigravity-fix =
        let
          src = prev.fetchFromGitHub {
            owner = "FutureisinPast";
            repo = "antigravity-conversation-fix";
            rev = "main";
            hash = "sha256-3V0vuXzlceulEf6HRigjK9IS4odvuaSJGmrwyOTZScA=";
          };
        in
        prev.writeShellScriptBin "antigravity-fix" ''
          exec ${prev.python3}/bin/python3 ${src}/rebuild_conversations.py "$@"
        '';

      google-gemini = prev.writeShellScriptBin "gemini" ''
        exec ${prev.nodejs}/bin/npx @google/gemini-cli@latest "$@"
      '';
    }
  )
]
