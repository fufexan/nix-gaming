{
  inputs,
  pkgs,
}: let
  inherit (pkgs) callPackage;

  wineBuilder = wine: build: extra:
    (import ./wine ({
        inherit inputs build pkgs;
        inherit (pkgs) callPackage fetchFromGitHub fetchurl lib moltenvk pkgsCross pkgsi686Linux stdenv_32bit;
        supportFlags = (import ./wine/supportFlags.nix).${build};
      }
      // extra))
    .${wine};

  packages = rec {
    osu-lazer-bin = callPackage ./osu-lazer-bin {};

    osu-stable = callPackage ./osu-stable {
      wine = wine-osu;
      wine-discord-ipc-bridge = wine-discord-ipc-bridge.override {wine = wine-osu;};
    };

    technic-launcher = callPackage ./technic-launcher {};

    wine-discord-ipc-bridge = callPackage ./wine-discord-ipc-bridge {wine = wine-tkg;};

    # broken
    #winestreamproxy = callPackage ./winestreamproxy { wine = wine-tkg; };

    wine-ge = wineBuilder "wine-ge" "full" {};

    wine-osu = wineBuilder "wine-osu" "base" {};

    wine-tkg = wineBuilder "wine-tkg" "base" {};

    wine-tkg-full = wineBuilder "wine-tkg" "full" {};
  };
in
  packages
