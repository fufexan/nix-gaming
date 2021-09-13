{ lib
, wine
, tkgPatches
, oglfPatches
, self
}:

let
  inherit (self.lib) mkPatches;
in
(
  wine.overrideAttrs (old: rec {
    # read all regular files from dir and apply them as patches
    patches = lib.concatLists [
      (mkPatches "${tkgPatches}/wine-tkg-git/wine-tkg-patches")
      (mkPatches "${oglfPatches}/patches")
      (mkPatches ./patches)
    ];

    meta = old.meta // { description = old.meta.description + ", with TKG patches applied"; };
  })
)
