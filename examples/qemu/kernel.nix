{ lib
, fetchFromGitHub
, nixosLite
}:

with nixosLite.linux;

let

  source = prepareSource {
    version = "5.2.15";
    src = fetchFromGitHub {
      owner = "torvalds";
      repo = "linux";
      rev = "58e2cf5d794616b84f591d4d1276c8953278ce24";
      hash = "sha256-qVzaKeFqLxBb3AEK1QydIitSqwQdQRKA6iPYK/zmJIc=";
    };
    patches = with kernelPatches; [
      # ...
    ];
  };

  configBase = makeConfig {
    inherit source;
    target = "defconfig";
  };

  # $ nix-shell -A my-kernel.configEnv
  # $ mm # alias for make $makeFlags menuconfig
  # (navigate and set CONFIG_BINFMT_ELF=n)
  # $ ms # alias for make $makeFlags savedefconfig

  config = configBase;

  # config = makeConfig {
  #   inherit source;
  #   target = "alldefconfig";
  #   allconfig = ./defconfig;
  # };

in buildKernel rec {
  inherit source config;
  dtbs = true;
}
