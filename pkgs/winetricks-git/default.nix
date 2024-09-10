{
  pins,
  lib,
  stdenv,
  perl,
  which,
  coreutils,
  zenity,
  curl,
  cabextract,
  unzip,
  p7zip,
  gnused,
  gnugrep,
  bash,
}: let
  inherit (pins) winetricks;
in
  stdenv.mkDerivation rec {
    pname = "winetricks";
    version = "git+${winetricks.revision}";

    src = winetricks;

    buildInputs = [perl which];

    # coreutils is for sha1sum
    pathAdd = lib.makeBinPath [
      perl
      which
      coreutils
      zenity
      curl
      cabextract
      unzip
      p7zip
      gnused
      gnugrep
      bash
    ];

    makeFlags = ["PREFIX=$(out)" "VERSION=development"];

    doCheck = false; # requires "bashate"

    postInstall = ''
      sed -i \
        -e '2i PATH="${pathAdd}:$PATH"' \
        "$out/bin/winetricks"
    '';

    passthru = {
      inherit (src) updateScript;
    };

    meta = {
      description = "A script to install DLLs needed to work around problems in Wine";
      mainProgram = "winetricks";
      license = lib.licenses.lgpl21;
      homepage = "https://github.com/Winetricks/winetricks";
      platforms = with lib.platforms; linux;
      maintainers = with lib.maintainers; [fuzen];
    };
  }
