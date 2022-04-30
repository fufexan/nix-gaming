inputs: let
  inherit (inputs.nixpkgs.lib) hasSuffix filesystem genAttrs;

  pkgs = genSystems (system:
    import inputs.nixpkgs
    {
      inherit system;
      config.allowUnfree = true;
    });

  mkPatches = dir:
    map (e: /. + e)
    (builtins.filter
      (hasSuffix ".patch")
      (filesystem.listFilesRecursive dir));

  genSystems = genAttrs supportedSystems;

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

  supportedSystems = ["x86_64-linux"];
in {inherit mkPatches genSystems legendaryBuilder pkgs;}
