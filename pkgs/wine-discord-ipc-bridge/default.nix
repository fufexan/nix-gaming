{
  lib,
  stdenv,
  pins,
  wine,
  pkgsCross,
}: let
  pin = pins.wine-discord-ipc-bridge;
  version = builtins.replaceStrings ["v"] [""] pin.version;
in
  stdenv.mkDerivation {
    pname = "wine-discord-ipc-bridge";
    inherit version;

    src = pin;

    nativeBuildInputs = [pkgsCross.mingw32.stdenv.cc wine];

    installPhase = "mkdir -p $out/bin; cp winediscordipcbridge.exe $out/bin; cp winediscordipcbridge-steam.sh $out/bin";

    meta = {
      description = "Enable games running under wine to use Discord Rich Presence";
      homepage = "https://github.com/0e4ef622/wine-discord-ipc-bridge";
      license = lib.licenses.mit;
      maintainers = with lib.maintainers; [fufexan];
      platforms = ["x86_64-linux"];
    };
  }
