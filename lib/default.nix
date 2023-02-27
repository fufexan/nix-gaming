{inputs, ...}: {
  flake.lib = {
    mkPatches = let
      inherit (inputs.nixpkgs.lib) hasSuffix filesystem;
    in
      dir:
        map (e: /. + e)
        (builtins.filter
          (hasSuffix ".patch")
          (filesystem.listFilesRecursive dir));

  legendaryBuilder = {
    games ? {},
    opts ? {},
    system ? "",
  }:
    builtins.mapAttrs (
      name: value:
        pkgs.${system}.callPackage ../pkgs/legendary
        ({
            inherit (inputs.self.packages.${system}) wine-discord-ipc-bridge;
            pname = name;
          }
          // opts
          // value)
    )
    games;
  };
}
