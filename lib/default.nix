inputs:

let
  inherit (inputs.nixpkgs.lib) hasSuffix filesystem genAttrs;

  mkPatches = dir: map (e: /. + e)
    (builtins.filter
      (hasSuffix ".patch")
      (filesystem.listFilesRecursive dir));

  forAllSystems = genAttrs supportedSystems;

  supportedSystems = [ "x86_64-linux" ];
in
{
  inherit mkPatches forAllSystems;
}
