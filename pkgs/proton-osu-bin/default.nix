{
  lib,
  pins,
  stdenvNoCC,
  fetchzip,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "proton-osu-bin";
  inherit (pins.proton-osu) version;

  src = fetchzip {
    url = "https://github.com/whrvt/umubuilder/releases/download/${finalAttrs.version}/${finalAttrs.version}.tar.xz";
    inherit (builtins.fromJSON (builtins.readFile ./info.json)) hash;
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
    passthru.updateScript = ./update.sh;
  };
})
