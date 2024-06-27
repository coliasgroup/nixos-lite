{ lib
, kernel
, nixosLite
}:

let
  isCross = with kernel.stdenv; hostPlatform != buildPlatform;

  inherit (nixosLite) linuxRustNativeBuildInputs linuxRustEnv;
in

kernel.stdenv.mkDerivation (linuxRustEnv // {

  name = "hello-module";

  NIX_NO_SELF_RPATH = true;
  hardeningDisable = [ "all" ];

  nativeBuildInputs = kernel.moduleNativeBuildInputs ++ linuxRustNativeBuildInputs;

  dontFixup = true;

  src = lib.cleanSource ./src;

  makeFlags =  [
    "C=${kernel.dev}"
    "ARCH=${kernel.kernelArch}"
    "V=1"
  ] ++ lib.optionals isCross [
    "CROSS_COMPILE=${kernel.stdenv.cc.targetPrefix}"
  ];

  buildFlags = [
    "modules"
  ];

  installFlags = [
    "INSTALL_MOD_PATH=$(out)"
  ];

  installTargets = [
    "modules_install"
  ];

  postInstall = ''
    rm $out/lib/modules/*/modules.*
  '';

})
