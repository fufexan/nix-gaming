{
  description = "osu! on Nix";

  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs;
    utils.url = github:numtide/flake-utils;
  };

  outputs = { self, nixpkgs, utils }:
    let
      # expose overlay outside of fu so it doesn't get output as overlay.${system}
      overlay = final: prev: {
        wine-osu = prev.callPackage ./wine-osu.nix {};
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

            packages = { inherit (pkgs) wine-osu; };
          in
            {
              inherit packages;
              defaultPackage = packages.wine-osu;
            }
      ) // { inherit overlay; };
}
