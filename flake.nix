{
  description = "Gaming on Nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    utils.url = "github:gytis-ivaskevicius/flake-utils-plus/staging";

    oglfPatches = { url = "github:openglfreak/wine-tkg-userpatches/c5d849279c8a90123162d92413aa249c2f044dc0"; flake = false; };
    tkgPatches = { url = "github:Frogging-Family/wine-tkg-git/6.14.r6.g1bc4da9d"; flake = false; };
  };

  nixConfig = {
    substituters = [ "https://nix-gaming.cachix.org" ];
    trusted-public-keys = [ "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4=" ];
  };

  outputs = { self, nixpkgs, utils, ... }@inputs:
    utils.lib.mkFlake {
      inherit self inputs;

      # only x86 linux is supported by wine
      supportedSystems = [ "i686-linux" "x86_64-linux" ];

      # add overlay to channel
      channels.nixpkgs.overlaysBuilder = _: [ (import ./pkgs { inherit inputs self; }) ];

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
