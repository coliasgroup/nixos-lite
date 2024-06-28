{ lib, runCommand, writeText, python3
, dtbHelpers
}:

{ dtb, bootargs, initrdStart, initrd, stdoutPath ? null, kaslrSeed ? null }:

let

  dtsoIn = writeText "chosen.dtso.in" ''
    /dts-v1/;
    / {
      fragment@0 {
        target-path = "/";
        __overlay__ {
          chosen {
            bootargs = "${lib.concatStringsSep " " bootargs}";
            linux,initrd-start = <${initrdStart}>;
            linux,initrd-end = <@initrd_end@>;
            ${lib.optionalString (stdoutPath != null) ''
              stdout-path = "${stdoutPath}";
            ''}
            ${lib.optionalString (kaslrSeed != null) ''
              kaslr-seed = ${kaslrSeed};
            ''}
          };
        };
      };
    };
  '';

  dtso = runCommand "chosen.dtso" {
    nativeBuildInputs = [ python3 ];
  } ''
    initrd_size="$(stat --format %s ${initrd})"
    initrd_end="$(python3 -c "print(hex(${initrdStart} + $initrd_size))")"

    substitute ${dtsoIn} $out --subst-var-by initrd_end $initrd_end
  '';

in
with dtb-helpers; applyOverlay dtb (compileOverlay dtso)
