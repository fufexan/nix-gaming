{ lib
, SDL2
, alsa-lib
, appimageTools
, autoPatchelfHook
, fetchurl
, ffmpeg_4
, gamemode
, icu
, libkrb5
, lttngUst
, makeDesktopItem
, makeWrapper
, numactl
, openssl
, stdenvNoCC
, symlinkJoin
, writeShellScript
, pipewire_latency ? "24/96000"
, gmrun_enable ? true
}:
let
  version = "2022.226.0";
  appimageBin = fetchurl {
    url = "https://github.com/ppy/osu/releases/download/${version}/osu.AppImage";
    sha256 = "sha256-UZZEubx6byADBJ1THcZL541l5n7TqoKgEgbchxMv/RY=";
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
    installPhase =
      let
        # dirty hack to infiltrate gamemoderun in the wrapper
        gmrun = writeShellScript "gmrun" ''
          shift
          exec ${gamemode}/bin/gamemoderun "''$@"
        '';
      in
      ''
        runHook preInstall
        install -d $out/bin $out/lib
        install osu\!.png $out/osu.png
        cp -r usr/bin $out/lib/osu
        makeWrapper $out/lib/osu/osu\! $out/bin/osu-lazer \
          --set COMPlus_GCGen0MaxBudget "600000" \
          --set PIPEWIRE_LATENCY "${pipewire_latency}" \
          --set vblank_mode "0" \
          --suffix LD_LIBRARY_PATH : "${lib.makeLibraryPath buildInputs}" ${if gmrun_enable then ''--run "${gmrun} \\"'' else ""}
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
