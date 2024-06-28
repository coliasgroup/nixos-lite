{ lib, otherSplices }:

self: with self;

{
  inherit otherSplices;

  linux = callPackage ./linux {};

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

  uBoot = callPackage ./u-boot {};

  dtbHelpers = callPackage ./dtb-helpers {};

  eval = callPackage ./eval.nix {};
}
