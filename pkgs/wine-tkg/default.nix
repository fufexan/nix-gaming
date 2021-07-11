{ lib
, wine
, tkgPatches
, oglfPatches
, ...
}:

(
  wine.overrideAttrs (
    old: rec {
      # read all regular files from dir and apply them as patches
      patches = lib.mapAttrsToList (n: v: n)
        (lib.filterAttrs (n: v: v == "regular" && n != "winepulse-v6.10-wasapifriendly.patch")
          ((builtins.readDir "${tkgPatches}/wine-tkg-git/wine-tkg-patches")
            // builtins.readDir "${oglfPatches}/patches"))
      ++ [
        ./patches/0001-Revert-to-5.14-winepulse.drv.patch
        ./patches/0002-5.14-Latency-Fix.patch
      ];

      meta = old.meta // { description = old.meta.description + ", with TKG patches applied"; };
    }
  )
)
