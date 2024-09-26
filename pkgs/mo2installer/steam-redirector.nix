{
  overrideCC,
  pkgsCross,
  version,
  src,
}: let
  useWin32ThreadModel = stdenv:
    overrideCC stdenv (
      stdenv.cc.override (old: {
        cc = old.cc.override {
          threadsCross = {
            model = "win32";
            package = null;
          };
        };
      })
    );
in
  (useWin32ThreadModel pkgsCross.mingwW64.stdenv).mkDerivation {
    pname = "steam-redirector";
    inherit version src;

    patches = [
      # The .exe won't compile with the -lpthread flag
      ./fix.patch
    ];

    buildPhase = ''
      cd steam-redirector/

      make "main.exe"
    '';

    installPhase = ''
      install -Dm0755 main.exe $out/main.exe
    '';
  }
