{
  description = "Gaming on Nix";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = inputs @ {
    self,
    nixpkgs,
  }: {
    lib = import ./lib inputs;

    overlays.default = _: prev:
      import ./pkgs {
        inherit inputs;
        pkgs = prev;
      };

    packages = self.lib.genSystems (system:
      self.overlays.default null (import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      }));

    nixosModules.pipewireLowLatency = import ./modules/pipewireLowLatency.nix;
    nixosModules.default = inputs.self.nixosModules.pipewireLowLatency;

    formatter = self.lib.genSystems (system: nixpkgs.legacyPackages.${system}.alejandra);
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
