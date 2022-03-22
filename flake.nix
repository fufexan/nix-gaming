{
  description = "Gaming on Nix";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs";

  nixConfig = {
    substituters = [ "https://cache.nixos.org" "https://nix-gaming.cachix.org" ];
    trusted-public-keys = [ "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=" "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4=" ];
  };

  outputs = { self, nixpkgs, ... }@inputs:
    # only x86 linux is supported by wine
    let
      lib = import ./lib inputs;

      apps = lib.forAllSystems (system: {
        osu-lazer = {
          program = packages.${system}.osu-lazer-bin.outPath + "/bin/osu-lazer";
          type = "app";
        };
      });

      overlays.default = final: prev: import ./pkgs {
        inherit inputs;
        pkgs = prev;
      };

      packages = lib.forAllSystems (system:
        (import ./pkgs {
          inherit inputs;
          pkgs = import nixpkgs { inherit system; config.allowUnfree = true; };
        }));
    in
    {
      inherit apps lib overlays packages;

      nixosModules.pipewireLowLatency = import ./modules/pipewireLowLatency.nix;
      nixosModule = inputs.self.nixosModules.pipewireLowLatency;
    };
}
