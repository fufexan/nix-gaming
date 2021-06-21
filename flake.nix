{
  description = "osu! on Nix";

  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs;
    utils.url = github:numtide/flake-utils;
    discord-ipc-bridge = {
      url = github:hitomi-team/discord-ipc-bridge;
      flake = false;
    };
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
          wine = final.wine-osu;
          dib = final.discord-ipc-bridge;
        };

        wine-osu = prev.callPackage ./pkgs/wine-osu {};
      };
    in
      # only x86 linux is supported by wine
      utils.lib.eachSystem [ "i686-linux" "x86_64-linux" ] (
        system:
          let
            pkgs = import nixpkgs {
              inherit system;
              overlays = [ overlay ];
            };

            apps.osu-stable = utils.lib.mkApp { drv = packages.osu-stable; };
            packages = { inherit (pkgs) discord-ipc-bridge osu-stable wine-osu; };
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
