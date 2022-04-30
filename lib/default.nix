inputs: let
  inherit (inputs.nixpkgs.lib) hasSuffix filesystem genAttrs;
  pkgs = genSystems (system: import inputs.nixpkgs {inherit system;});

  mkPatches = dir:
    map (e: /. + e)
    (builtins.filter
      (hasSuffix ".patch")
      (filesystem.listFilesRecursive dir));

  genSystems = genAttrs supportedSystems;

  supportedSystems = ["x86_64-linux"];
in {inherit mkPatches genSystems;}
