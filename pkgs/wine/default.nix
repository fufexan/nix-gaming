{
  inputs,
  pins,
  lib,
  build,
  pkgs,
  pkgsCross,
  pkgsi686Linux,
  callPackage,
  fetchFromGitHub,
  fetchurl,
  moltenvk,
  supportFlags,
  stdenv_32bit,
}: let
  defaults = let
    sources = (import "${inputs.nixpkgs}/pkgs/applications/emulators/wine/sources.nix" {inherit pkgs;}).unstable;
  in {
    inherit supportFlags moltenvk;
    patches = [];
    buildScript = "${inputs.nixpkgs}/pkgs/applications/emulators/wine/builder-wow.sh";
    configureFlags = ["--disable-tests"];
    geckos = with sources; [gecko32 gecko64];
    mingwGccs = with pkgsCross; [mingw32.buildPackages.gcc mingwW64.buildPackages.gcc];
    monos = with sources; [mono];
    pkgArches = [pkgs pkgsi686Linux];
    platforms = ["x86_64-linux"];
    stdenv = stdenv_32bit;
  };

  pnameGen = n: n + lib.optionalString (build == "full") "-full";
in {
  wine-ge = callPackage "${inputs.nixpkgs}/pkgs/applications/emulators/wine/base.nix" (defaults
    // {
      pname = pnameGen "wine-ge";
      version = pins.proton-wine.branch;
      src = pins.proton-wine;
    });

  wine-tkg = callPackage "${inputs.nixpkgs}/pkgs/applications/emulators/wine/base.nix" (defaults
    // rec {
      pname = pnameGen "wine-tkg";
      version = lib.removeSuffix "\n" (lib.removePrefix "Wine version " (builtins.readFile "${src}/VERSION"));
      src = pins.wine-tkg;
    });

  wine-osu = let
    pname = pnameGen "wine-osu";
    version = "7.0";
    staging = fetchFromGitHub {
      owner = "wine-staging";
      repo = "wine-staging";
      rev = "v${version}";
      sha256 = "sha256-2gBfsutKG0ok2ISnnAUhJit7H2TLPDpuP5gvfMVE44o=";
    };
  in
    (callPackage "${inputs.nixpkgs}/pkgs/applications/emulators/wine/base.nix" (defaults
      // rec {
        inherit version pname;
        src = fetchFromGitHub {
          owner = "wine-mirror";
          repo = "wine";
          rev = "wine-${version}";
          sha256 = "sha256-uDdjgibNGe8m1EEL7LGIkuFd1UUAFM21OgJpbfiVPJs=";
        };
        patches = ["${inputs.nixpkgs}/pkgs/applications/emulators/wine/cert-path.patch"] ++ inputs.self.lib.mkPatches ./patches;
      }))
    .overrideDerivation (_: {
      prePatch = ''
        patchShebangs tools
        cp -r ${staging}/patches .
        chmod +w patches
        cd patches
        patchShebangs gitapply.sh
        ./patchinstall.sh DESTDIR="$PWD/.." --all ${lib.concatMapStringsSep " " (ps: "-W ${ps}") []}
        cd ..
      '';
    });
}
