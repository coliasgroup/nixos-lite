let
  defaultNixpkgsPath =
    let
      rev = "9e1960bc196baf6881340d53dccb203a951745a2";
    in
      builtins.fetchTarball {
        url = "https://github.com/NixOS/nixpkgs/archive/${rev}.tar.gz";
        sha256 = "sha256:1bgarnk1akwzkmq6hc890zra6psqir1q44jsnc3j8xiaw6bdgyc7";
      };

  # nixpkgsPath = ../../../../nixpkgs;

  nixpkgsPath = defaultNixpkgsPath;

  fenixRev = "9af557bccdfa8fb6a425661c33dbae46afef0afa";
  fenixSource = fetchTarball "https://github.com/nix-community/fenix/archive/${fenixRev}.tar.gz";
  fenix = import fenixSource {};

  fenixToolchain = fenix.fromToolchainName {
    name = "1.78.0";
    sha256 = "sha256-opUgs6ckUQCyDxcB9Wy51pqhd0MPGHUVbwRKKPGiwZU=";
  };

  pkgs = import nixpkgsPath {
    crossSystem = {
      config = "aarch64-unknown-linux-gnu";
      # config = "aarch64-unknown-none-elf";
    };
    overlays = [
      (import ../overlay.nix)
      (self: super: {
        nixosLite = super.nixosLite // {
          linux = super.nixosLite.linux.overrideScope (scopeSelf: scopeSuper: {
            linuxRustEnvironment = {
              inherit (fenixToolchain) toolchain;
              bindgen = scopeSelf.bindgen_0_65_1.override {
                clang = self.clang_13;
              };
            };
          });
        };
      })
    ];
  };

in rec {
  inherit pkgs;

  qemu = pkgs.callPackage ./qemu {};
}
