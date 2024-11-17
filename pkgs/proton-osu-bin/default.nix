{
  lib,
  stdenvNoCC,
  fetchzip,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "proton-osu-bin";
  version = "proton-osu-9-10";

  src = fetchzip {
    url = "https://github.com/whrvt/umubuilder/releases/download/${finalAttrs.version}/${finalAttrs.version}.tar.xz";
    hash = "sha256-wX3ScZu6n1WSNtbKU/7U1oiL9bc+udOCwMVlfqY3p7I=";
  };

  outputs = [
    "out"
    "steamcompattool"
  ];

  buildCommand = ''
    runHook preBuild

    echo "${finalAttrs.pname} should not be installed into environments. Please use programs.steam.extraCompatPackages instead." > $out

    ln -s $src $steamcompattool

    runHook postBuild
  '';

  meta = {
    description = ''
      Compatibily tool for Steam Play, patched with low-latency audio and intended for osu!.

      (This is intended for use in the `programs.steam.extraCompatPackages` option only.)
    '';
    homepage = "https://github.com/whrvt/umubuilder";
    license = lib.licenses.gpl3Plus;
    platforms = ["x86_64-linux"];
  };
})