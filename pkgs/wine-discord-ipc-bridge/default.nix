{
  lib,
  stdenv,
  fetchFromGitHub,
  wine,
  pkgsCross,
}:
stdenv.mkDerivation rec {
  pname = "wine-discord-ipc-bridge";
  version = "0.0.2";

  src = fetchFromGitHub {
    repo = pname;
    owner = "0e4ef622";
    rev = "v${version}";
    sha256 = "sha256-D0N9iHwRHGmnve12Z8Lgz4NTXpv4HBL1Q5IKOP06P5g=";
  };

  nativeBuildInputs = [pkgsCross.mingw32.stdenv.cc wine];

  installPhase = "mkdir -p $out/bin; cp winediscordipcbridge.exe $out/bin";

  meta = {
    description = "Enable games running under wine to use Discord Rich Presence";
    homepage = "https://github.com/0e4ef622/wine-discord-ipc-bridge";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [fufexan];
    platforms = with lib.platforms; ["x86_64-linux"];
  };
}
