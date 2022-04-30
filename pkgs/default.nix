{
  inputs,
  pkgs,
}: let
  wineBuilder = wine: build: extra:
    (import ./wine ({
        inherit inputs build pkgs;
        inherit (pkgs) lib pkgsCross pkgsi686Linux fetchFromGitHub fetchurl moltenvk callPackage stdenv_32bit;
        supportFlags = (import ./wine/supportFlags.nix).${build};
      }
      // extra))
    .${wine};

  inherit (pkgs) callPackage;
in rec {
  osu-lazer-bin = callPackage ./osu-lazer-bin {};

  osu-stable = callPackage ./osu-stable {
    wine = wine-osu;
    wine-discord-ipc-bridge = wine-discord-ipc-bridge.override {wine = wine-osu;};
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
