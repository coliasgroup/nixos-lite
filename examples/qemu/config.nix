{ lib, config, pkgs, ... }:

with lib;

let

in {
  net.interfaces = {
    eth0 = {};
  };

  initramfs.extraUtilsCommands = ''
    copy_bin_and_libs ${pkgs.curl.bin}/bin/curl
  '';

  initramfs.extraInitCommands = ''
    curl example.com
  '';
}
