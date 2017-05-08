{ stdenv, lib, fetchFromGitHub, writeTextFile, gcc-arm-embedded-4_7
, clockRate, mcu
}:

let
  linkerScript = (lib.toLower mcu) + ".ld";
in
  stdenv.mkDerivation rec {
    name    = "teensy3-core-${version}";
    version = "1.3.1";
    src  = fetchFromGitHub {
      owner  = "PaulStoffregen";
      repo   = "cores";
      rev    = "3a6e99ca1ca3ed3948e90fa72d8e27f787f3dd03";
      sha256 = "0lqdnxqyvmgs1841z10nzzkp4cv8h1njfz3379nmm2xh3h4jhxck";
    };

    buildInputs = [
      gcc-arm-embedded-4_7
    ];

    phases = ["unpackPhase" "buildPhase" "installPhase"];

    buildPhase = ''
      rm -f teensy3/main.cpp

      substitute ${./flags.mk} ./teensy3/flags.mk \
        --subst-var-by clockRate ${toString clockRate} \
        --subst-var-by mcu ${mcu}

      substitute ${./Makefile} ./teensy3/Makefile \
        --subst-var-by linkerScript ${linkerScript}

      make -C teensy3
      ar rvs libteensy3-core.a *.o
    '';

    installPhase = ''
      mkdir -p $out/{include,lib}
      mkdir $out/lib/pkgconfig

      mv *.a $out/lib
      cp teensy3/* $out/include -R;

      rm $(find $out -name "*.c" -o -name "*.cpp")

      substitute ${./teensy3-core.pc} $out/lib/pkgconfig/teensy3-core.pc \
        --subst-var-by out $out \
        --subst-var-by version ${version} \
        --subst-var-by linkerScript ${linkerScript}
    '';
  }
