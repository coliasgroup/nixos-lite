{ lib
, callPackage
, pkgsBuildBuild
, nixosLite
}:

rec {

  kernel = callPackage ./kernel.nix {};

  outOfTreeModule = callPackage ./module.nix {
    inherit kernel;
  };

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

  userland = nixosLite.eval {
    modules = [
      ./config.nix
    ];
  };

  inherit (userland.config.build) initramfs;

  simulate = pkgsBuildBuild.writeScript "simulate" ''
    #!${pkgsBuildBuild.runtimeShell}
    exec ${pkgsBuildBuild.qemu}/bin/qemu-system-aarch64 ${lib.concatStringsSep " " qemuArgs}
  '';

}
