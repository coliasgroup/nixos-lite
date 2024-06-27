{ stdenv, lib, buildPackages
, bison, flex
, linuxRustNativeBuildInputs, linuxRustEnv
}:

{ source
, config
, args
, kernelArch ? stdenv.hostPlatform.linuxArch
}:

let
  isCross = stdenv.hostPlatform != stdenv.buildPlatform;

in
stdenv.mkDerivation (linuxRustEnv // {

  name = "linux-${source.version}${source.extraVersion}.config";

  depsBuildBuild = [ buildPackages.stdenv.cc ];
  nativeBuildInputs = [ bison flex ] ++ linuxRustNativeBuildInputs;

  phases = [ "buildPhase" ];

  buildPhase = ''
    cat ${config} > $out
    bash ${source}/scripts/config --file $out ${lib.concatStringsSep " " args}
  '';

})
