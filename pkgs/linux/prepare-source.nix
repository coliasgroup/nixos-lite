{ stdenv, writeText }:

{ src, version, extraVersion ? "", ... } @ args:

stdenv.mkDerivation ({

  name = "linux-source";

  dontBuild = true;
  dontFixup = true;

  installPhase = ''
    runHook preInstall

    root=$(pwd)
    cd $NIX_BUILD_TOP
    mv $root $out

    runHook postInstall
  '';

} // removeAttrs args [ "version" "extraVersion" ] // {

  passthru = {
    inherit version extraVersion;
    fullVersion = version + extraVersion;
  };

})
