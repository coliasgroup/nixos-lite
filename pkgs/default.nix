{ lib
, callPackage
, newScope
, splicePackages
, generateSplicesForMkScope
}:

{
  eval = callPackage ./eval.nix {};

  linux =
    let
      otherSplices = generateSplicesForMkScope "nixosLiteLinux";
    in
      lib.makeScopeWithSplicing
        splicePackages
        newScope
        otherSplices
        (_: {})
        (_: {})
        (callPackage ./linux {
          inherit otherSplices;
        })
      ;

  uBoot =
    let
      otherSplices = generateSplicesForMkScope "nixosLiteUBoot";
    in
      lib.makeScopeWithSplicing
        splicePackages
        newScope
        otherSplices
        (_: {})
        (_: {})
        (callPackage ./u-boot {
          inherit otherSplices;
        })
      ;

  dtbHelpers = callPackage ./dtb-helpers {};
}
