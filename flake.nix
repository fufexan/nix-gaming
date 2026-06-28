{
  description = "Gaming on Nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-compat = {
      url = "github:NixOS/flake-compat";
      flake = false;
    };

    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-compat.follows = "flake-compat";
      };
    };
  };

  outputs =
    { self, ... }@inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        ./lib
        ./modules
        ./pkgs
        ./tests
        ./fmt-hooks.nix
      ];

      perSystem =
        { config, pkgs, ... }:
        {
          formatter = pkgs.nixfmt-tree;
          # Add to legacyPackages to prevent easyOverlay from including this package in the Overlay.
          legacyPackages.npins = pkgs.callPackage (
            let
              pins = import ./npins;
            in
            pins.npins + "/npins.nix"
          ) { };

          devShells.default = pkgs.mkShell {
            packages = [ config.legacyPackages.npins ];
            shellHook = ''
              ${config.pre-commit.installationScript}
            '';
          };
        };
    };

  # auto-fetch deps when `nix run/shell`ing
  nixConfig = {
    allowInsecure = true;
    extra-substituters = [ "https://nix-gaming.cachix.org" ];
    extra-trusted-public-keys = [
      "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
    ];
  };
}
