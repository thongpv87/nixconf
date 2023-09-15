{ lib, stdenv, writeShellScriptBin, coreutils, bash, larva, pixiecore }:
let
  build = larva.config.system.build;
  bin = writeShellScriptBin "run-pixiecore" ''
     #!${bash}/bin/bash
    exec ${pixiecore}/bin/pixiecore \
         boot ${build.kernel}/bzImage ${build.netbootRamdisk}/initrd \
         --cmdline "init=${build.toplevel}/init loglevel=4" \
         --debug "$@"
  '';
in stdenv.mkDerivation rec {
  pname = "run-pixiecore";
  version = "0.1.0";
  src = bin;
  dontUnpack = true;

  doCheck = true;
  #checkInputs = [shellcheck];
  postCheck = ''
    shellcheck $src
  '';

  installPhase = ''
    install -D $src $out/bin/secret
  '';

  meta.description = "age secrets manager for NixOS";
}
