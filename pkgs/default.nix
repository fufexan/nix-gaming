{
  inputs,
  pkgs,
}: let
  wineBuilder = wine: build: extra:
    (import ./wine ({
        inherit inputs build pkgs;
        inherit (pkgs) callPackage fetchFromGitHub fetchurl lib moltenvk pkgsCross pkgsi686Linux stdenv_32bit;
        supportFlags = (import ./wine/supportFlags.nix).${build};
      }
      // extra))
    .${wine};

  inherit (pkgs) callPackage;
in rec {
  osu-lazer-bin = callPackage ./osu-lazer-bin {};

  osu-stable = callPackage ./osu-stable rec {
    wine = wine-osu;
    wine-discord-ipc-bridge = callPackage ./wine-discord-ipc-bridge {inherit wine;};
  };

  rocket-league = callPackage ./rocket-league {wine = wine-tkg;};

  technic-launcher = callPackage ./technic-launcher {};

  wine-discord-ipc-bridge = callPackage ./wine-discord-ipc-bridge {wine = wine-tkg;};

  # broken
  #winestreamproxy = callPackage ./winestreamproxy { wine = wine-tkg; };

  wine-osu = wineBuilder "wine-osu" "base" {};

  wine-tkg = wineBuilder "wine-tkg" "base" {};

  wine-tkg-full = wineBuilder "wine-tkg" "full" {};
}
