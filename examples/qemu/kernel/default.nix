{ lib
, fetchFromGitHub
, nixosLite
}:

with nixosLite.linux;

let

  source = prepareSource {
    version = "6.10-rc5";
    src = fetchFromGitHub {
      owner = "torvalds";
      repo = "linux";
      rev = "afcd48134c58d6af45fb3fdb648f1260b20f2326";
      hash = "sha256-TQp/fZNz/Vf9tyT5krtWsGUgfXJ1TojBhh49lnoXM9M=";
      # hash = lib.fakeHash;
    };
    patches = with kernelPatches; [
      # ...
    ];
  };

  baseConfig = makeConfig {
    inherit source;
    target = "defconfig";
  };

  baseDefConfig = savedefconfig {
    inherit source;
    config = baseConfig;
  };

  # $ nix-shell -A my-kernel.configEnv
  # $ mm # alias for make $makeFlags menuconfig
  # (navigate and set CONFIG_GCC_PLUGINS=n and CONFIG_RUST=y)
  # $ ms # alias for make $makeFlags savedefconfig

  # config = baseConfig;

  config = makeConfig {
    inherit source;
    target = "alldefconfig";
    allconfig = ./defconfig;
  };

in (buildKernel {
  inherit source config;
  modules = true;
  # dtbs = true;
  passthru = {
    inherit baseConfig baseDefConfig;
  };
}).overrideAttrs (attrs: {
  makeFlags = attrs.makeFlags ++ [
    # "V=1"
  ];
})
