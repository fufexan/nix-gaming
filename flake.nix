{
  description = "osu! on Nix";

  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs;
    utils.url = github:numtide/flake-utils;

    discord-ipc-bridge = {
      url = github:hitomi-team/discord-ipc-bridge;
      flake = false;
    };

    nixpkgs-tkg.url = "github:NixOS/nixpkgs";

    oglfPatches = { url = "github:openglfreak/wine-tkg-userpatches/ff6328a6b5e36dd8a007a7273290aa30ab3164d9"; flake = false; };
    tkgPatches = { url = "github:Frogging-Family/wine-tkg-git/257bfe71c045db0fbbb9f3896f9697068b9f482a"; flake = false; };
  };

  nixConfig = {
    substituters = [ "https://app.cachix.org/cache/osu-nix" ];
    trusted-public-keys = [ "osu-nix.cachix.org-1:vn/szRSrx1j0IA/oqLAokr/kktKQzsDgDPQzkLFR9Cg=" ];
  };

  outputs = { self, nixpkgs, utils, ... }@inputs:
    let
      # expose overlay outside of fu so it doesn't get output as overlay.${system}
      overlay = final: prev: {
        discord-ipc-bridge = prev.pkgsCross.mingw32.callPackage ./pkgs/discord-ipc-bridge {
          dib = inputs.discord-ipc-bridge;
        };

        osu-stable = prev.callPackage ./pkgs/osu-stable {
          wine = final.wine-tkg;
          winetricks = prev.winetricks.override { wine = final.wine-tkg; };
          inherit (final) winestreamproxy;
        };

        wine-osu = prev.callPackage ./pkgs/wine-osu { };

        winestreamproxy = prev.callPackage ./pkgs/winestreamproxy { wine = final.wineWowPackages.minimal; };

        wine-tkg = inputs.nixpkgs-tkg.legacyPackages.x86_64-linux.callPackage ./pkgs/wine-tkg { inherit (inputs) tkgPatches oglfPatches; };
      };
    in
    # only x86 linux is supported by wine
    utils.lib.eachSystem [ "i686-linux" "x86_64-linux" ]
      (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ overlay ];
          };

          apps.osu-stable = utils.lib.mkApp { drv = packages.osu-stable; };
          packages = { inherit (pkgs) discord-ipc-bridge osu-stable wine-osu wine-tkg winestreamproxy; };
        in
        {
          inherit apps packages;

          defaultApp = apps.osu-stable;
          defaultPackage = packages.osu-stable;
        }
      ) // {
      inherit overlay;

      nixosModules.pipewireLowLatency = import ./modules/pipewireLowLatency.nix;
      nixosModule = self.nixosModules.pipewireLowLatency;
    };
}
