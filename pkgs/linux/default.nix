{ lib, otherSplices }:

self: with self;

{
  inherit otherSplices;

  linuxRustEnvironment = null;

  linuxRustNativeBuildInputs = lib.optionals (linuxRustEnvironment != null) (
    with otherSplices.selfBuildBuild.linuxRustEnvironment; [
      toolchain
      bindgen
    ]
  );

  linuxRustEnv = lib.optionalAttrs (linuxRustEnvironment != null) {
    RUSTC = "rustc";
    CARGO = "cargo";
    BINDGEN = "bindgen";
    LIBCLANG_PATH = "${otherSplices.selfBuildBuild.linuxRustEnvironment.bindgen.clang.cc.lib}/lib";
  };

  readConfig = contents:
    let
      lines = lib.splitString "\n" contents;
      removeComments = lib.filter (line: line != "" && !(lib.hasPrefix "#" line));
      parseLine = line:
        let
          match = builtins.match ''CONFIG_([^=]*)=(.*)'' line;
        in
          lib.nameValuePair (lib.elemAt match 0) (lib.elemAt match 1);
    in
      lib.listToAttrs (map parseLine (removeComments lines));

  mkQueries = config: with lib; rec {
    attrs = config;
    isSet = attr: hasAttr attr attrs;
    get = attr: if isSet attr then getAttr attr attrs else null;
    isYes = attr: get attr == "y";
    isNo = attr: get attr == "n";
    isModule = attr: get attr == "m";
    isEnabled = attr: isModule attr || isYes attr;
    isDisabled = attr: !(isEnabled attr);
  };

  getDefconfig = callPackage ./config/get-defconfig.nix {};
  makeConfig = callPackage ./config/make-allconfig.nix {};
  configEnv = callPackage ./config/env.nix {};

  savedefconfig = callPackage ./config/make-savedefconfig.nix {};
  olddefconfig = callPackage ./config/make-olddefconfig.nix {};

  modifyConfig = callPackage ./config/modify-config.nix {};

  prepareSource = callPackage ./prepare-source.nix {};
  buildHeaders = callPackage ./build-headers.nix {};
  buildDtbs = callPackage ./build-dtbs.nix {};
  buildKernel = callPackage ./build-kernel.nix {
    inherit readConfig mkQueries configEnv;
  };

  kernelPatches = {
    scriptconfig = ./patches/scriptconfig.patch;
  };

  bindgen_0_65_1 = callPackage ./bindgen-0.65.1.nix {};

}

  # buildInfo =
  #   buildFlags = [
  #     "modules.builtin"
  #     "include/config/kernel.release"
  #   ];
