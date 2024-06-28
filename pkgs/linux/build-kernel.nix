{ stdenv, overrideCC, lib, buildPackages, nukeReferences
, nettools, bc, bison, flex, perl, rsync, gmp, libmpc, mpfr, openssl, libelf, utillinux, kmod, sparse
, python3

, linuxRustNativeBuildInputs, linuxRustEnv
, configEnv, readConfig, mkQueries
}:

{ source
, config
, dtbs ? false
, modules ? true
, headers ? false
, kernelArch ? stdenv.hostPlatform.linuxArch
, kernelTarget ? stdenv.hostPlatform.linux-kernel.target
, kernelInstallTarget ?
    { uImage = "uinstall";
      zImage = "zinstall";
    }.${kernelTarget} or "install"
, kernelFile ? null
, nukeRefs ? true
, verbose ? false
, passthru ? {}
}:

let
  kernelFileArg = kernelFile;
in

let
  isCross = stdenv.hostPlatform != stdenv.buildPlatform;

  moduleEnv = linuxRustEnv // {
    NIX_NO_SELF_RPATH = true;
    hardeningDisable = [ "all" ];
  };

  moduleNativeBuildInputs = [
    libelf kmod
  ] ++ linuxRustNativeBuildInputs;

  defaultKernelFile = "${if kernelTarget == "zImage" then "vmlinuz" else "vmlinux"}-${source.version}${source.extraVersion}";
  kernelFile = if kernelFileArg != null then kernelFileArg else defaultKernelFile;

in
stdenv.mkDerivation (finalAttrs: moduleEnv // {

  name = "linux-${source.fullVersion}";

  outputs = [
    "out" "dev"
  ] ++ lib.optionals modules [
    "mod"
  ] ++ lib.optionals dtbs [
    "dtbs"
  ] ++ lib.optionals headers [
    "hdrs"
  ];

  enableParallelBuilding = true;

  NIX_NO_SELF_RPATH = true;
  hardeningDisable = [ "all" ];

  depsBuildBuild = [
    buildPackages.stdenv.cc
    # for menuconfig in shell
    buildPackages.pkgconfig
    buildPackages.ncurses
  ];

  nativeBuildInputs = [
    bison flex bc perl python3
    nettools utillinux
    openssl gmp libmpc mpfr
  ] ++ lib.optionals headers [
    rsync
  ] ++ lib.optionals nukeRefs [
    nukeReferences
  ] ++ moduleNativeBuildInputs;

  dontUnpack = true;
  dontPatch = true;
  dontFixup = true;

  configurePhase = ''
    mkdir $dev
    cp -v ${config} $dev/.config
  '';

  makeFlags =  [
    "-C" "${source}"
    "O=$(dev)"
    "ARCH=${kernelArch}"
  ] ++ lib.optionals isCross [
    "CROSS_COMPILE=${stdenv.cc.targetPrefix}"
  ] ++ lib.optionals verbose [
    "V=1"
  ];

  buildFlags = [
    kernelTarget
  ] ++ lib.optionals modules [
    "modules"
  ] ++ lib.optionals dtbs [
    "dtbs"
  ];

  installFlags = [
    "INSTALL_PATH=$(out)"
  ] ++ lib.optionals modules [
    "INSTALL_MOD_PATH=$(mod)"
  ] ++ lib.optionals dtbs [
    "INSTALL_DTBS_PATH=$(dtbs)"
  ] ++ lib.optionals headers [
    "INSTALL_HDR_PATH=$(hdrs)"
  ];
    # "INSTALL_MOD_STRIP=1"

  installTargets = [
    kernelInstallTarget
  ] ++ lib.optionals modules [
    "modules_install"
  ] ++ lib.optionals dtbs [
    "dtbs_install"
  ] ++ lib.optionals headers [
    "headers_install"
  ];

  postInstall = ''
    release="$(cat $dev/include/config/kernel.release)"
  '' + lib.optionalString modules ''
    rm -f $mod/lib/modules/$release/{source,build}
  '' + lib.optionalString headers ''
    find $hdrs -name ..install.cmd -delete
  '' + lib.optionalString nukeRefs ''
    find $out -type f -exec nuke-refs {} \;
    find $mod -type f -exec nuke-refs {} \;
  '';

  passthru = {
    inherit source kernelArch;
    inherit (source) version;
    inherit stdenv moduleNativeBuildInputs moduleEnv;
    configFile = config;
    config = mkQueries (readConfig (builtins.readFile config));
    kernel = "${finalAttrs.finalPackage.out}/${kernelFile}";
    inherit kernelFile;
    modDirVersion = source.version;

    configEnv = configEnv {
      inherit source config;
    };

  } // passthru;

    shellHook = ''
      config=${config}
      source=$PWD
      obj=$PWD
      v() {
        echo "$@"
        "$@"
      }
      c() {
        cp -v --no-preserve=ownership,mode $config .config
      }
      s() {
        source=$(realpath ''${1:-.})
      }
      m() {
        v make -C $source O=$obj ARCH=${kernelArch} ${lib.optionalString isCross "CROSS_COMPILE=${stdenv.cc.targetPrefix}"} -j$NIX_BUILD_CORES "$@"
      }
      mb() {
        v m ${lib.concatStringsSep " " finalAttrs.finalPackage.buildFlags} "$@"
      }
      mi() {
        mkdir -pv $out $mod $dtbs $hdrs
        v m ${lib.concatMapStringsSep " " (x: "'${x}'") finalAttrs.finalPackage.installFlags} ${lib.concatStringsSep " " finalAttrs.finalPackage.installTargets} "$@"
      }
      export out=$PWD/out
      export mod=$PWD/mod
      export dtbs=$PWD/dtbs
      export hdrs=$PWD/hdrs
    '';

})
