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
    extra-substituters = ["https://nix-gaming.cachix.org"];
    extra-trusted-public-keys = ["nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="];
  };
}
