{
  inputs,
  self,
  ...
}: {
  systems = ["x86_64-linux"];

  imports = [inputs.flake-parts.flakeModules.easyOverlay];

  perSystem = {
    config,
    system,
    pkgs,
    ...
  }: {
    _module.args.pkgs = import inputs.nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };

    packages = let
      pins = import ../npins;

      wineBuilder = wine: build: extra:
        (import ./wine ({
            inherit inputs self pkgs build pins;
            inherit (pkgs) callPackage fetchFromGitHub fetchurl lib moltenvk pkgsCross pkgsi686Linux stdenv_32bit;
            supportFlags = (import ./wine/supportFlags.nix).${build};
          }
          // extra))
        .${wine};
    in {
      dxvk = pkgs.callPackage ./dxvk {inherit pins;};
      dxvk-w32 = pkgs.pkgsCross.mingw32.callPackage ./dxvk {inherit pins;};
      dxvk-w64 = pkgs.pkgsCross.mingwW64.callPackage ./dxvk {inherit pins;};

      faf-client = pkgs.callPackage ./faf-client {};
      faf-client-unstable = pkgs.callPackage ./faf-client {unstable = true;};

      osu-mime = pkgs.callPackage ./osu-mime {};

      osu-lazer-bin = pkgs.callPackage ./osu-lazer-bin {
        inherit pins;
        inherit (config.packages) osu-mime;
      };

      osu-stable = pkgs.callPackage ./osu-stable {
        wine = config.packages.wine-osu;
        wine-discord-ipc-bridge = config.packages.wine-discord-ipc-bridge.override {wine = config.packages.wine-osu;};
      };

      proton-ge = pkgs.callPackage ./proton-ge {};

      roblox-player = pkgs.callPackage ./roblox-player {
        wine = config.packages.wine-tkg;
        inherit (config.packages) wine-discord-ipc-bridge;
      };

      rocket-league = pkgs.callPackage ./rocket-league {wine = config.packages.wine-tkg;};

      technic-launcher = pkgs.callPackage ./technic-launcher {};

      vkd3d-proton = pkgs.callPackage ./vkd3d-proton {inherit pins;};
      vkd3d-proton-w32 = pkgs.pkgsCross.mingw32.callPackage ./vkd3d-proton {inherit pins;};
      vkd3d-proton-w64 = pkgs.pkgsCross.mingwW64.callPackage ./vkd3d-proton {inherit pins;};

      wine-discord-ipc-bridge = pkgs.callPackage ./wine-discord-ipc-bridge {
        inherit pins;
        wine = config.packages.wine-tkg;
      };

      # broken
      #winestreamproxy = callPackage ./winestreamproxy { wine = wine-tkg; };

      wine-ge = wineBuilder "wine-ge" "full" {};

      wine-osu = wineBuilder "wine-osu" "base" {};

      wine-tkg = wineBuilder "wine-tkg" "full" {};

      wineprefix-preparer = pkgs.callPackage ./wineprefix-preparer {inherit (config.packages) dxvk-w32 vkd3d-proton-w32 dxvk-w64 vkd3d-proton-w64;};
    };
  };
}
