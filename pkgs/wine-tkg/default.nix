{ lib
, wineWow ? true
, wineUnstable
, wineWowPackages
, tkgPatches
, oglfPatches
, ...
}:

let
  wine = if wineWow then wineWowPackages.unstable else wineUnstable;
in
(
  wine.overrideAttrs (
    old: rec {
      # read all regular files from dir and apply them as patches
      patches = lib.mapAttrsToList (n: v: n) (lib.filterAttrs (n: v: v == "regular") ((builtins.readDir "${tkgPatches}/wine-tkg-git/wine-tkg-patches") // builtins.readDir "${oglfPatches}/patches"));
      meta = old.meta // { description = old.meta.description + ", with TKG patches applied"; };
    }
  )
)
