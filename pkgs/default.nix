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

  legendaryBuilder = {
    games ? {},
    opts ? {},
  }:
    builtins.mapAttrs (
      name: value:
        callPackage ./legendary
        ({
            inherit (packages) wine-discord-ipc-bridge;
            pname = name;
          }
          // opts
          // value)
    )
    games;

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

    wine-osu = wineBuilder "wine-osu" "base" {};

    wine-tkg = wineBuilder "wine-tkg" "base" {};

    wine-tkg-full = wineBuilder "wine-tkg" "full" {};

    inherit
      (legendaryBuilder {
        games = {
          rocket-league = {
            desktopName = "Rocket League";
            tricks = ["dxvk" "win10"];
            icon = builtins.fetchurl {
              url = "https://www.pngkey.com/png/full/16-160666_rocket-league-png.png";
              name = "rocket-league.png";
              sha256 = "09n90zvv8i8bk3b620b6qzhj37jsrhmxxf7wqlsgkifs4k2q8qpf";
            };
            discordIntegration = false;
          };
        };

        opts.wine = packages.wine-tkg;
      })
      rocket-league
      ;
  };
in
  packages
