{ lib
, callPackage
, pkgsBuildBuild
, nixosLite
}:

rec {

  kernel = callPackage ./kernel {};

  helloModule = callPackage ./hello-module {
    inherit kernel;
  };

  userland = nixosLite.eval {
    modules = [
      ./config.nix
      {
        initramfs = {
          modules = nixosLite.linux.aggregateModules {
            modules = [
              kernel.mod
              helloModule
            ];
          };

          includeModules = [ "hello" ];
        };
      }
    ];
  };

  inherit (userland.config.build) initramfs;

  bootArgs = [
    "console=ttyAMA0"
    # "loglevel=7"
    # "keep_bootcon"
  ];

  qemuArgs = [
    "-machine" "virt"
    "-cpu cortex-a57"
    "-m" "size=1G"
    "-nographic"
    "-serial" "mon:stdio"
    "-kernel" "${kernel}/vmlinux*"
    "-initrd" initramfs
    "-append" "'${lib.concatStringsSep " " bootArgs}'"
  ];

  simulate = pkgsBuildBuild.writeScript "simulate" ''
    #!${pkgsBuildBuild.runtimeShell}
    exec ${pkgsBuildBuild.qemu}/bin/qemu-system-aarch64 ${lib.concatStringsSep " " qemuArgs}
  '';

}
