{ lib, otherSplices }:

self: with self;

{
  inherit otherSplices;

  getDefconfig = callPackage ./config/get-defconfig.nix {};
  makeConfig = callPackage ./config/make-allconfig.nix {};
  configEnv = callPackage ./config/env.nix {};

  savedefconfig = callPackage ./config/make-savedefconfig.nix {};
  olddefconfig = callPackage ./config/make-olddefconfig.nix {};

  prepareSource = callPackage ./prepare-source.nix {};
  build = callPackage ./build.nix {};
  buildTools = callPackage ./build-tools.nix {};

  tools = callPackage ./tools {};
  mkImage = callPackage ./mkimage.nix {};
  mkImageFit = callPackage ./mkimage-fit.nix {};
}
