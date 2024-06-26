{ otherSplices }:

self: with self;

{
  inherit otherSplices;

  kconfigCommon = callPackage ./common {};

  linux = callPackage ./linux {
    inherit kconfigCommon;
  };

  uBoot = callPackage ./u-boot {};

  dtbHelpers = callPackage ./dtb-helpers {};

  eval = callPackage ./eval.nix {};
}
