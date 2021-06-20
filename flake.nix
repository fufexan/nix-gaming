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

  outputs = { self, nixpkgs, utils, ... }@inputs:
    let
      # expose overlay outside of fu so it doesn't get output as overlay.${system}
      overlay = final: prev: {
        discord-ipc-bridge = prev.pkgsCross.mingw32.callPackage ./pkgs/discord-ipc-bridge {
          dib = inputs.discord-ipc-bridge;
        };

        osu = prev.callPackage ./pkgs/osu {
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

            packages = { inherit (pkgs) discord-ipc-bridge osu wine-osu; };
          in
            {
              inherit packages;
              defaultPackage = packages.osu;
            }
      ) // {
        inherit overlay;

        nixosModules.pipewireLowLatency = import ./modules/pipewireLowLatency.nix;
        nixosModule = self.nixosModules.pipewireLowLatency;
      };
}
