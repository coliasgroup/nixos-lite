{ stdenv, lib, buildPackages
, bison, flex
, linuxRustNativeBuildInputs, linuxRustEnv
}:

{ source
, target
, allconfig ? null
, kernelArch ? stdenv.hostPlatform.linuxArch
}:

let
  isCross = stdenv.hostPlatform != stdenv.buildPlatform;

in
stdenv.mkDerivation (linuxRustEnv // {

  name = "linux-${source.version}${source.extraVersion}-${target}.config";

  depsBuildBuild = [ buildPackages.stdenv.cc ];
  nativeBuildInputs = [ bison flex ] ++ linuxRustNativeBuildInputs;

  phases = [ "buildPhase" "installPhase" ];

  makeFlags = [
    "-C" "${source}"
    "O=$(PWD)"
    "ARCH=${kernelArch}"
  ] ++ lib.optionals isCross [
    "CROSS_COMPILE=${stdenv.cc.targetPrefix}"
  ] ++ lib.optionals (allconfig != null) [
    "KCONFIG_ALLCONFIG=${allconfig}"
  # ] ++ [
  #   "KCONFIG_CONFIG=$(out)"
  ];

  installPhase = ''
    mv .config $out
  '';

  buildFlags = [
    target
  ];

})
