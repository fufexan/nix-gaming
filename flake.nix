{
  description = "osu! on Nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    utils.url = "github:gytis-ivaskevicius/flake-utils-plus/staging";

    nixpkgs-wine-osu.url = "github:NixOS/nixpkgs/73b982e62194a5d85827d87b0851aee06932979f";

    discord-ipc-bridge = { url = github:hitomi-team/discord-ipc-bridge; flake = false; };
    oglfPatches = { url = "github:openglfreak/wine-tkg-userpatches/ff6328a6b5e36dd8a007a7273290aa30ab3164d9"; flake = false; };
    tkgPatches = { url = "github:Frogging-Family/wine-tkg-git/257bfe71c045db0fbbb9f3896f9697068b9f482a"; flake = false; };
  };

  nixConfig = {
    substituters = [ "https://app.cachix.org/cache/osu-nix" ];
    trusted-public-keys = [ "osu-nix.cachix.org-1:vn/szRSrx1j0IA/oqLAokr/kktKQzsDgDPQzkLFR9Cg=" ];
  };

  outputs = { self, nixpkgs, utils, ... }@inputs:
    utils.lib.mkFlake {
      inherit self inputs;
      # only x86 linux is supported by wine
      supportedSystems = [ "i686-linux" "x86_64-linux" ];

      # add overlay to channel
      channels.nixpkgs.overlaysBuilder = _: [ (import ./pkgs { inherit inputs; }) ];

      # output each overlay in its own set
      overlays = utils.lib.exportOverlays { inherit (self) pkgs inputs; };

      # build outputs
      outputsBuilder = channels: rec {
        apps.osu-stable = utils.lib.mkApp { drv = packages.osu-stable; };
        defaultApp = apps.osu-stable;
        defaultPackage = packages.osu-stable;
        packages = utils.lib.exportPackages self.overlays channels;
      };

      # create module by path
      nixosModules = utils.lib.exportModules [ ./modules/pipewireLowLatency.nix ];
      nixosModule = self.nixosModules.pipewireLowLatency;
    };
}
