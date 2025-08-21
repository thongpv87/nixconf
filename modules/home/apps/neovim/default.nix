{
  config,
  pkgs,
  lib,
  ...
}:
with lib;
let
  cfg = config.nixconf.apps.neovim;
  # neovimPkgs = pkgs.neovim.override { withNodeJs = true; };

  inherit (lib)
    mkOption
    mkMerge
    mkIf
    mkDefault
    mkForce
    types
    mdDoc
    mkEnableOption
    ;
in
{
  options.nixconf.apps.neovim = {
    enable = mkOption {
      description = "Enable neovim with lazyvim config";
      type = types.bool;
      default = false;
    };
  };

  config = mkIf cfg.enable {
    home.sessionPath = [ "$HOME/.local/bin" ];
    home.sessionVariables = {
      # DOTNET_SYSTEM_GLOBALIZATION_INVARIANT = "true";
    };

    programs.neovim = {
      enable = true;
      viAlias = true;
      vimAlias = true;
      vimdiffAlias = true;
      withNodeJs = true;
      withPython3 = true;

      extraPackages = [
        pkgs.sqlite
        pkgs.gcc
        pkgs.lazygit
        pkgs.ripgrep
        pkgs.fd
        pkgs.coreutils
        pkgs.gnumake
        pkgs.git
        pkgs.nixd
        pkgs.luarocks
        pkgs.lua
        pkgs.cargo
        pkgs.stack
        pkgs.cacert
      ];
      extraWrapperArgs = [
        "--suffix"
        "LIBRARY_PATH"
        ":"
        "${lib.makeLibraryPath [
          pkgs.stdenv.cc.cc
          pkgs.zlib
          pkgs.lua-language-server
          pkgs.icu.dev
          pkgs.gnumake
          pkgs.cacert
        ]}"
        "--suffix"
        "PKG_CONFIG_PATH"
        ":"
        "${lib.makeSearchPathOutput "dev" "lib/pkgconfig" [
          pkgs.stdenv.cc.cc
          pkgs.zlib
        ]}"
      ];
    };

    home.packages = with pkgs; [
      #neovimPkgs
      #myvim
      sqlite
      gcc
      lazygit
      ripgrep
      fd
      coreutils
      fd
      gnumake
      git
      nixd
      selected-nerdfonts
      luarocks
      lua
      cargo
      zlib
      zlib.dev
      #nodejs
      stack
    ];

    xdg.dataFile."fonts/kodama-regular.ttf".source = ./fonts/Kodama-0.0.0-Regular.ttf;
  };
}
