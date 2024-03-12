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
        ./pkgs
        ./tests
      ];

      flake.nixosModules = let
        inherit (inputs.nixpkgs) lib;
      in {
        pipewireLowLatency = import ./modules/pipewireLowLatency.nix;

        steamCompat = throw ''
          nix-gaming.nixosModules.steamCompat is deprecated as of 2024-03-12 due to the addition of
          `programs.steam.extraCompatPackages` to nixpkgs.

          See https://github.com/NixOS/nixpkgs/pull/293564 for more details. You may remove the steamCompat
          module to supress this message.
        '';

        default = throw ''
          The usage of default module is deprecated as multiple modules are provided by nix-gaming. Please use
          the exact name of the module you would like to use. Available modules are:

          ${builtins.concatStringsSep "\n" (lib.filter (name: name != "default") (lib.attrNames self.nixosModules))}
        '';
      };

      perSystem = {pkgs, ...}: {
        formatter = pkgs.alejandra;
      };
    };

  # auto-fetch deps when `nix run/shell`ing
  nixConfig = {
    allowInsecure = true;
    extra-substituters = ["https://nix-gaming.cachix.org"];
    extra-trusted-public-keys = ["nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="];
  };
}
