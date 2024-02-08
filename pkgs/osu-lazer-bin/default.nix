{
  fetchurl,
  fetchzip,
  osu-lazer-bin,
  pins,
  stdenv,
}:
osu-lazer-bin.overrideAttrs (oldAttrs: rec {
  inherit (pins.osu) version;

  # TODO: I didn't figure out how to use lib.resursiveUpdate here,
  #       so I ended up copying the entire thing.

  # TODO: ./info.json's order is wrong, for some reason.
  #       we should make it a set instead of a list, like `jq -r '.aarch64-darwin.hash'`
  #       but I don't know how to do it in bash, at the moment it just works (tm).
  src = let
    baseUrl = "https://github.com/ppy/osu/releases/download/${version}";
    infoFile = builtins.fromJSON (builtins.readFile ./info.json);
  in
    {
      aarch64-darwin = fetchzip {
        inherit (builtins.elemAt infoFile 2) hash;
        url = "${baseUrl}/osu.app.Apple.Silicon.zip";
        striproot = false;
      };
      x86_64-darwin = fetchzip {
        inherit (builtins.elemAt infoFile 1) hash;
        url = "${baseUrl}/osu.app.Intel.zip";
        striproot = false;
      };
      x86_64-linux = fetchurl {
        inherit (builtins.elemAt infoFile 0) hash;
        url = "${baseUrl}/osu.AppImage";
      };
    }
    .${stdenv.system}
    or (throw "${oldAttrs.pname}-${version}: ${stdenv.system} is unsupported.");

  passthru.updateScript = ./update.sh;
})
