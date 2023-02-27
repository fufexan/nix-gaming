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

    legendaryBuilder = pkgs: {
      games ? {},
      opts ? {},
    }:
      builtins.attrValues (builtins.mapAttrs (
          name: value:
            pkgs.callPackage ../pkgs/legendary
            ({
                inherit (inputs.self.packages.${pkgs.hostPlatform.system}) wine-discord-ipc-bridge;
                pname = name;
              }
              // opts
              // value)
        )
        games);
  };
}
