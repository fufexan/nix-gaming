{
  description = "osu! on Nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    utils.url = "github:numtide/flake-utils";

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
    let
      # expose overlay outside of fu so it doesn't get output as overlay.${system}
      overlay = final: prev: {
        osu-stable = prev.callPackage ./pkgs/osu-stable {
          wine = final.wine-tkg;
          winetricks = prev.winetricks.override { wine = final.wine-tkg; };
          inherit (final) winestreamproxy;
        };

        winestreamproxy = prev.callPackage ./pkgs/winestreamproxy { wine = final.wine-tkg; };

        wine-tkg = prev.callPackage ./pkgs/wine-tkg {
          wine =
            if prev.system == "x86_64-linux"
            then final.wineWowPackages.unstable
            else final.wineUnstable;
          inherit (inputs) tkgPatches oglfPatches;
        };

        # --- deprecated ---
        discord-ipc-bridge = prev.pkgsCross.mingw32.callPackage ./pkgs/discord-ipc-bridge { dib = inputs.discord-ipc-bridge; };

        wine-osu =
          let
            nwo = inputs.nixpkgs-wine-osu.legacyPackages.${prev.system};
          in
          nwo.callPackage ./pkgs/wine-osu { wine = nwo.wineUnstable; };
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
