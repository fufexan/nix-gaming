{
  pkgs,
  overrideCC,
  ...
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
  (useWin32ThreadModel pkgs.pkgsCross.mingwW64.stdenv).mkDerivation {
    pname = "steam-redirector";
    version = "5.0.3";

    src = pkgs.fetchFromGitHub {
      owner = "rockerbacon";
      repo = "modorganizer2-linux-installer";
      rev = "90d33013aca0deceaadc099be4d682e08f237ef5";
      sha256 = "sha256-RYN5/t5Hmzu+Tol9iJ+xDmLGY9sAkLTU0zY6UduJ4i0=";
    };

    patches = [./fix.patch];

    buildPhase = ''
      cd steam-redirector/

      make "main.exe"
    '';

    installPhase = ''
      ls

      install -Dm0755 main.exe $out/main.exe

    '';
  }
