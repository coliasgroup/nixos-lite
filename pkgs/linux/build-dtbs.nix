{ stdenv, overrideCC, lib, buildPackages, nukeReferences
, nettools, bc, bison, flex, perl, rsync, gmp, libmpc, mpfr, openssl, libelf, utillinux, kmod
}:

{ source
, config
, kernelArch ? stdenv.hostPlatform.linuxArch
}:

let
  isCross = stdenv.hostPlatform != stdenv.buildPlatform;

in
stdenv.mkDerivation {

  name = "linux-dtbs-${source.fullVersion}";

  enableParallelBuilding = true;

  NIX_NO_SELF_RPATH = true;
  hardeningDisable = [ "all" ];

  depsBuildBuild = [ buildPackages.stdenv.cc ];
  nativeBuildInputs = [
    bison flex bc perl
    nettools utillinux
    openssl gmp libmpc mpfr libelf
    kmod
  ];

  dontUnpack = true;
  dontPatch = true;
  dontFixup = true;

  configurePhase = ''
    cp -v ${config} .config
  '';

  makeFlags =  [
    "-C" "${source}"
    "O=$(PWD)"
    "ARCH=${kernelArch}"
  ] ++ lib.optionals isCross [
    "CROSS_COMPILE=${stdenv.cc.targetPrefix}"
  ];

  buildFlags = [
    "dtbs"
  ];

  installFlags = [
    "INSTALL_DTBS_PATH=$(out)"
  ];

  installTargets = [
    "dtbs_install"
  ];

}
