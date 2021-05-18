{
  description = "osu! on Nix";

  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs;
    utils.url = github:numtide/flake-utils;
  };

  outputs = { self, nixpkgs, utils }:
    utils.lib.eachSystem [ "i686-linux" "x86_64-linux" ] (
      system:
        let
          overlay = final: prev: {
            wine-osu = prev.callPackage ./wine-osu.nix {};
          };

          pkgs = import nixpkgs {
            inherit system;
            overlays = [ overlay ];
          };

          packages = { inherit (pkgs) wine-osu; };
        in
          {
            inherit packages overlay;
            defaultPackage = packages.wine-osu;
          }
    );
}
