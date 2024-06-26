self: super: with self; {

  nixosLite =
    let
      otherSplices = generateSplicesForMkScope "nixosLite";
    in
      lib.makeScopeWithSplicing
        splicePackages
        newScope
        otherSplices
        (_: {})
        (_: {})
        (import ./pkgs {
          inherit otherSplices;
        })
      ;

}
