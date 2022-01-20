{ lib
, SDL2
, alsa-lib
, appimageTools
, autoPatchelfHook
, fetchurl
, ffmpeg_4
, icu
, libkrb5
, lttngUst
, makeDesktopItem
, makeWrapper
, numactl
, openssl
, stdenvNoCC
, symlinkJoin
}:
let
  version = "2022.118.0";
  appimageBin = fetchurl {
    url = "https://github.com/ppy/osu/releases/download/${version}/osu.AppImage";
    sha256 = "sha256-6yuOtWX3xl6Q7NJ7VdV0fBQZelqzqgpx5OX5eSZTejE=";
  };
  extracted = appimageTools.extract {
    inherit version;
    pname = "osu.AppImage";
    src = appimageBin;
  };
  derivation = stdenvNoCC.mkDerivation rec {
    inherit version;
    name = "osu-lazer-bin";
    src = extracted;
    buildInputs = [
      SDL2
      alsa-lib
      ffmpeg_4
      icu
      libkrb5
      lttngUst
      numactl
      openssl
    ];
    nativeBuildInputs = [
      autoPatchelfHook
      makeWrapper
    ];
    autoPatchelfIgnoreMissingDeps = true;
    installPhase = ''
      runHook preInstall
      install -d $out/bin $out/lib
      install osu\!.png $out/osu.png
      cp -r usr/bin $out/lib/osu
      makeWrapper $out/lib/osu/osu\! $out/bin/osu-lazer \
        --set COMPlus_GCGen0MaxBudget "600000" \
        --set PIPEWIRE_LATENCY "24/96000" \
        --set vblank_mode "0" \
        --suffix LD_LIBRARY_PATH : "${lib.makeLibraryPath buildInputs}"
      runHook postInstall
    '';
    fixupPhase = ''
      runHook preFixup
      ln -sft $out/lib/osu ${SDL2}/lib/libSDL2${stdenvNoCC.hostPlatform.extensions.sharedLibrary}
      runHook postFixup
    '';
  };
  desktopItem = makeDesktopItem {
    name = "osu-lazer-bin";
    exec = "${derivation.outPath}/bin/osu-lazer";
    icon = "${derivation.outPath}/osu.png";
    comment = "A free-to-win rhythm game. Rhythm is just a *click* away!";
    desktopName = "osu!";
    categories = "Game;";
  };
in
symlinkJoin {
  inherit version;
  name = "osu-lazer-bin";
  paths = [ derivation desktopItem ];

  meta = {
    description = "Rhythm is just a *click* away";
    longDescription = "osu-lazer extracted from the official AppImage to retain multiplayer support.";
    homepage = "https://osu.ppy.sh";
    license = with lib.licenses; [
      mit
      cc-by-nc-40
      unfreeRedistributable # osu-framework contains libbass.so in repository
    ];
    platforms = [ "x86_64-linux" ];
  };
}
