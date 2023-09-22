{
  description = "Gaming on Nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake {inherit inputs;} {
      flake.nixosModules = {
        pipewireLowLatency = import ./modules/pipewireLowLatency.nix;
        steamCompat = import ./modules/steamCompat.nix;
        default = throw ''
          The usage of default module is deprecated as multiple modules are provided by nix-gaming. Please use
          the exact name of the module you would like to use.
        '';
      };

      imports = [
        ./lib
        ./pkgs
      ];

      perSystem = {pkgs, ...}: {
        formatter = pkgs.alejandra;
      };
    };

  # auto-fetch deps when `nix run/shell`ing
  nixConfig = {
    extra-substituters = ["https://nix-gaming.cachix.org"];
    extra-trusted-public-keys = ["nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="];
  };
}
