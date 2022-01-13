{
  description = "Gaming on Nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    utils.url = "github:gytis-ivaskevicius/flake-utils-plus";
  };

  nixConfig = {
    substituters = [ "https://cache.nixos.org" "https://nix-gaming.cachix.org" ];
    trusted-public-keys = [ "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=" "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4=" ];
  };

  outputs = { self, nixpkgs, utils, ... }@inputs:
    utils.lib.mkFlake {
      inherit self inputs;

      # only x86 linux is supported by wine
      supportedSystems = [ "i686-linux" "x86_64-linux" ];

      # add overlay to channel
      channels.nixpkgs.overlaysBuilder = _: [ (import ./pkgs { inherit inputs self; }) ];
      channelsConfig.allowUnfree = true;

      # output each overlay in its own set
      overlays = utils.lib.exportOverlays { inherit (self) pkgs inputs; };

      lib.mkPatches = import ./lib { inherit inputs; };

      # build outputs
      outputsBuilder = channels: rec {
        apps.osu-stable = utils.lib.mkApp { drv = packages.osu-stable; };
        packages = utils.lib.exportPackages self.overlays channels;
      };

      # create module by path
      nixosModules = utils.lib.exportModules [ ./modules/pipewireLowLatency.nix ];
      nixosModule = self.nixosModules.pipewireLowLatency;
    };
}
