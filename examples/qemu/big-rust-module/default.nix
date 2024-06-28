{ lib
, runCommand
, rustPlatform
, remarshal
, kernel
}:

let
  isCross = with kernel.stdenv; hostPlatform != buildPlatform;

  toTOMLFile = name: expr: runCommand name {
    nativeBuildInputs = [
      remarshal
    ];
    json = builtins.toJSON expr;
    passAsFile = [ "json" ];
  } ''
    remarshal -if json -of toml -i $jsonPath -o $out
  '';

  target = "aarch64-unknown-none";

  profile = "kmod";

  sysroot = runCommand "sysroot" {} ''
    d=$out/lib/rustlib/${target}/lib
    mkdir -p $d
    cp ${kernel.dev}/rust/{*.rmeta,*.o} $d
  '';

  config = toTOMLFile "config.toml" {
    unstable.unstable-options = true;
    target."${target}".rustflags = [
      # "-Z" "unstable-options"

      "--sysroot=${sysroot}"
      # "--extern=force:alloc"
      "--extern=kernel"
      "-L${kernel.dev}/rust"

      "-Zbinary_dep_depinfo=y"
      "-Cembed-bitcode=n" "-Cforce-unwind-tables=n" "-Csymbol-mangling-version=v0" "-Crelocation-model=static"
      "-Zfunction-sections=n"
      "-Ctarget-feature=-neon"
      "-Zbranch-protection=pac-ret"
      "-Cforce-frame-pointers=y"

      "--emit=obj"

      "--cfg=MODULE"
      "@${kernel.dev}/include/generated/rustc_cfg"
    ];

    source.crates-io.replace-with = "vendored-sources";
    source.vendored-sources.directory = cargoDeps;
  };

  cargoDeps = rustPlatform.importCargoLock {
    lockFile = ./package/Cargo.lock;
  };

  package = kernel.stdenv.mkDerivation (kernel.moduleEnv // {
    name = "package";

    src = lib.cleanSourceWith {
      src = ./package;
      filter = name: type:
        let baseName = baseNameOf (toString name);
        in !(type == "directory" && baseName == "target");
    };

    nativeBuildInputs = kernel.moduleNativeBuildInputs;

    dontConfigure = true;
    dontInstall = true;
    dontFixup = true;

    RUSTC_BOOTSTRAP = 1;

    CONFIG = config;
    PROFILE = profile;

    buildPhase = ''
      RUST_MODFILE=/dev/null \
        cargo build \
          --config ${config} \
          --profile=${profile} \
          --target=${target}

      d=target/${target}/${profile}/deps

      mkdir $out
      cp -r $d $out/deps
      $CC -r -o $out/package.o -Wl,--whole-archive $out/deps/*.o
    '';

    passthru = {
      inherit cargoDeps;
    };
  });

in
kernel.stdenv.mkDerivation (kernel.moduleEnv // {

  name = "module";

  nativeBuildInputs = kernel.moduleNativeBuildInputs;

  dontConfigure = true;
  dontFixup = true;

  src = lib.cleanSource ./src;

  preBuild = ''
    cp ${package}/package.o big_rust.o
  '';

  makeFlags =  [
    "C=${kernel.dev}"
    "ARCH=${kernel.kernelArch}"
    "V=1"
  ] ++ lib.optionals isCross [
    "CROSS_COMPILE=${kernel.stdenv.cc.targetPrefix}"
  ];

  buildFlags = [
    "modules"
  ];

  installFlags = [
    "INSTALL_MOD_PATH=$(out)"
  ];

  installTargets = [
    "modules_install"
  ];

  postInstall = ''
    rm $out/lib/modules/*/modules.*
  '';

  passthru = {
    inherit sysroot package;
  };
})

/*

RUST_MODFILE=/build/source/hello_rust
  rustc
    --edition=2021
    -Zbinary_dep_depinfo=y
    -Dunsafe_op_in_unsafe_fn -Drust_2018_idioms -Dunreachable_pub -Dnon_ascii_idents
    -Wmissing_docs
    -Drustdoc::missing_crate_level_docs
    -Dclippy::correctness -Dclippy::style -Dclippy::suspicious -Dclippy::complexity -Dclippy::perf -Dclippy::let_unit_value -Dclippy::mut_mut -Dclippy::needless_bitwise_bool -Dclippy::needless_continue -Dclippy::no_mangle_with_rust_abi
    -Wclippy::dbg_macro
    -Cpanic=abort -Cembed-bitcode=n -Clto=n -Cforce-unwind-tables=n -Ccodegen-units=1 -Csymbol-mangling-version=v0 -Crelocation-model=static
    -Zfunction-sections=n
    -Dclippy::float_arithmetic
    --target=aarch64-unknown-none
    -Ctarget-feature="-neon"
    -Zbranch-protection=pac-ret
    -Copt-level=2 -Cdebug-assertions=n -Coverflow-checks=y -Cforce-frame-pointers=y -Cdebuginfo=1
    --cfg MODULE
    @./include/generated/rustc_cfg
    -Zallow-features=new_uninit
    -Zcrate-attr=no_std -Zcrate-attr='feature(new_uninit)'
    -Zunstable-options
    --extern force:alloc --extern kernel
    --crate-type rlib
    -L ./rust/
    --crate-name hello_rust
    --sysroot=/dev/null
    --out-dir /build/source/
    --emit=dep-info=/build/source/.hello_rust.o.d
    --emit=obj=/build/source/hello_rust.o
    /build/source/hello_rust.rs

*/
