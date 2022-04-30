{
  description = "Gaming on Nix";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = inputs @ {
    self,
    nixpkgs,
  }: let
    # helper functions
    lib = import ./lib inputs;

    # in case you want to add the packages to your pkgs
    overlays.default = _: prev:
      import ./pkgs {
        inherit inputs;
        pkgs = prev;
      };

    packages = lib.genSystems (system:
      import ./pkgs {
        inherit inputs;
        pkgs = lib.pkgs.${system};
      });
  in {
    inherit lib overlays packages;

    nixosModules.pipewireLowLatency = import ./modules/pipewireLowLatency.nix;
    nixosModules.default = inputs.self.nixosModules.pipewireLowLatency;
  };

  # auto-fetch deps when `nix run/shell`ing
  nixConfig = {
    substituters = [
      "https://cache.nixos.org"
      "https://nix-gaming.cachix.org"
    ];

    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
    ];
  };
}
