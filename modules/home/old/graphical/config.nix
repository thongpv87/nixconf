{ pkgs, config, lib, ... }:
with lib; {
  config.nixconf.old.graphical = { enable = mkDefault false; };
}
