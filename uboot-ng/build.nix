{ stdenv, lib, buildPackages, hostPlatform, buildPlatform
, bc, bison, dtc, flex, openssl, python2, swig
}:

{ source
, config
, kernelArch ? stdenv.hostPlatform.platform.kernelArch
, filesToInstall
, passthru ? {}
}:

let
  isCross = stdenv.hostPlatform != stdenv.buildPlatform;

in stdenv.mkDerivation rec {

  name = "u-boot-${source.fullVersion}";

  phases = [ "configurePhase" "buildPhase" "installPhase" ];

  NIX_NO_SELF_RPATH = true;
  hardeningDisable = [ "all" ];

  # make[2]: *** No rule to make target 'lib/efi_loader/helloworld.efi', needed by '__build'.  Stop.
  enableParallelBuilding = false;

  depsBuildBuild = [ buildPackages.stdenv.cc ];
  nativeBuildInputs = [ bc bison dtc flex openssl python2 swig ];

  configurePhase = ''
    cp -v ${config} .config
  '';

  makeFlags =  [
    "-C" "${source}"
    "O=$(PWD)"
    # "V=1"
    # "ARCH=${kernelArch}"
    "DTC=dtc"
  ] ++ lib.optionals isCross [
    "CROSS_COMPILE=${stdenv.cc.targetPrefix}"
  ];

  buildFlags = filesToInstall;

  installPhase = ''
    mkdir $out
    cp ${stdenv.lib.concatStringsSep " " filesToInstall} $out
  '';

  inherit passthru;

}

  # echo 'ccflags-y += -DDEBUG' >> scripts/Makefile.build
  # "CONFIG_DM_DEBUG=y"