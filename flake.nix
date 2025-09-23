{
  description = "Gaming on Nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = {self, ...} @ inputs:
    inputs.flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [
        ./lib
        ./modules
        ./pkgs
        ./tests
      ];

      perSystem = {pkgs, ...}: {
        formatter = pkgs.alejandra;
        # Add to legacyPackages to prevent easyOverlay from including this package in the Overlay.
        legacyPackages.npins = pkgs.callPackage (let pins = import ./npins; in pins.npins + "/npins.nix") {};
      };
    };

  # auto-fetch deps when `nix run/shell`ing
  nixConfig = {
    allowInsecure = true;
    extra-substituters = ["https://nix-gaming.cachix.org"];
    extra-trusted-public-keys = ["nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="];
  };
}
