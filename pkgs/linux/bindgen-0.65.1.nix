
{ lib, fetchCrate, rustPlatform, clang, rustfmt
}:
let
  # bindgen hardcodes rustfmt outputs that use nightly features
  rustfmt-nightly = rustfmt.override { asNightly = true; };
in
rustPlatform.buildRustPackage rec {
  pname = "bindgen";
  version = "0.65.1";

  src = fetchCrate {
    pname = "bindgen-cli";
    inherit version;
    sha256 = "sha256-9JJXQQSbCxTh3fIbVSrc6WAYGivwomkoB8ZIquUNr9o=";
  };

  cargoHash = "sha256-EyIfvhXo2aLe2Ua75+ESD3UCg4Ckn9LI/HjzLCEzLFc=";

  buildInputs = [ clang.cc.lib ];

  preConfigure = ''
    export LIBCLANG_PATH="${clang.cc.lib}/lib"
  '';

  doCheck = true;
  nativeCheckInputs = [ clang ];

  RUSTFMT = "${rustfmt-nightly}/bin/rustfmt";

  preCheck = ''
    # for the ci folder, notably
    patchShebangs .
  '';

  passthru = { inherit clang; };
}
