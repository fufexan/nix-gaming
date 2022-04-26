{ pkgsCross, gcc
, fetchFromGitHub
, lib
, meson, ninja, wineWowPackages, glslang
, wine-staging
, x64 ? true
}:
let
  version = "1.9.2";
  dxvk-async = fetchFromGitHub {
    owner = "Sporif";
    repo = "dxvk-async";
    rev = version;
    sha256 = "sha256-gsdJ9g13xvsQ995fvl7AIyTM6aED2IDNTJIhYAfkQ2k=";
  };

  wine =
    if x64 then
      wineWowPackages.staging
    else
      wine-staging;

  crossPkgs =
    if x64 then
      pkgsCross.mingwW64
    else
      pkgsCross.mingw32;

in
crossPkgs.stdenv.mkDerivation rec {
  name = "dxvk";
  inherit version;

  buildInputs = [ crossPkgs.windows.pthreads ];

  nativeBuildInputs =
    [ meson
      ninja
      glslang
      gcc
      wine
    ];

  patches = [
    (dxvk-async + "/dxvk-async.patch")
  ];

  # NIX_CFLAGS_COMPILE = "-I ${wineWowPackages.staging}/include/wine/windows";
  mesonFlags = [ "--buildtype=release" "--includedir=${wine}/include/wine/windows" ];

  preConfigure = ''
    awk -i inplace -v where="128" -v what=" arguments : [ '-i', '@INPUT@', '-I', '${wine}/include/wine/windows', '-o', '@OUTPUT@' ])" 'FNR==where {print what; next} 1' meson.build
  '';

  src = fetchFromGitHub {
    owner = "doitsujin";
    repo = "dxvk";
    rev = "v" + version;
    sha256 = "sha256-bV7YfA1fYsK9rzrdXB5OODmY6zr/Mo+BOutRvdhVTF4=";
  };
}
