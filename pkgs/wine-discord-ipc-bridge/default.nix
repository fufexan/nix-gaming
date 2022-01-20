{ lib
, stdenv
, fetchFromGitHub
, wine
, pkgsCross
}:

stdenv.mkDerivation rec {
  pname = "wine-discord-ipc-bridge";
  version = "unstable-2022-01-05";

  src = fetchFromGitHub {
    repo = pname;
    owner = "0e4ef622";
    rev = "a61da30aad3edfccc084097dff621565f70535f3";
    sha256 = "sha256-X9g81SIs7pp0I3Ft7/1QzEIXhWXqMmLhv7lQoBPi3fY=";
  };

  nativeBuildInputs = [ pkgsCross.mingw32.stdenv.cc wine ];

  installPhase = "mkdir -p $out/bin; cp winediscordipcbridge.exe $out/bin";

  meta = {
    description = "Enable games running under wine to use Discord Rich Presence";
    homepage = "https://github.com/0e4ef622/wine-discord-ipc-bridge";
    license = lib.licenses.mit;
    maintainers = [ lib.maintainers.fufexan ];
    platforms = with lib.platforms; [ "i686-linux" "x86_64-linux" ];
  };
}
