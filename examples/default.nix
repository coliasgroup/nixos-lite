let
  defaultNixpkgsPath =
    let
      rev = "9e1960bc196baf6881340d53dccb203a951745a2";
    in
      builtins.fetchTarball {
        url = "https://github.com/NixOS/nixpkgs/archive/${rev}.tar.gz";
        sha256 = "sha256:1bgarnk1akwzkmq6hc890zra6psqir1q44jsnc3j8xiaw6bdgyc7";
      };

  # defaultNixpkgsPath =
  #   let
  #     rev = "1811c4fec88995679397d6fa20f4f3395a0bebe5";
  #   in
  #     builtins.fetchTarball {
  #       url = "https://github.com/coliasgroup/nixpkgs/archive/refs/tags/keep/${builtins.substring 0 32 rev}.tar.gz";
  #       sha256 = "sha256:0ad2c7vlr9fidzjjg8szigfhmp1gvlf62ckd6cir8ymrxc93pby7";
  #     };

  # nixpkgsPath = ../../../../nixpkgs;

  nixpkgsPath = defaultNixpkgsPath;

  pkgs = import nixpkgsPath {
    crossSystem = {
      config = "aarch64-unknown-linux-gnu";
      # config = "aarch64-unknown-none-elf";
    };
    overlays = [
      (import ../overlay.nix)
    ];
  };

in rec {
  inherit pkgs;

  qemu = pkgs.callPackage ./qemu {};
}
