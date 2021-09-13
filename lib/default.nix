{ inputs }:
let
  inherit (inputs.nixpkgs.lib) hasSuffix filesystem;

  mkPatches = dir: map (e: builtins.toPath e)
    (builtins.filter
      (e: hasSuffix ".patch" e)
      (filesystem.listFilesRecursive dir));
in
mkPatches
