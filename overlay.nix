self: super: with self; {

  nixosLite = callPackage ./pkgs {};

  nixosLiteLinux = nixosLite.linux;
  nixosLiteUBoot = nixosLite.uBoot;
}
