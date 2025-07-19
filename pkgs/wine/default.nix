{
  inputs,
  self,
  pins,
  lib,
  build,
  pkgs,
  pkgsCross,
  pkgsi686Linux,
  callPackage,
  fetchFromGitHub,
  moltenvk,
  supportFlags,
  gccMultiStdenv,
  overrideCC,
  wrapCCMulti,
  gcc13,
  stdenv,
  wine-mono,
}: let
  nixpkgs-wine = builtins.path {
    path = inputs.nixpkgs;
    name = "source";
    filter = path: type: let
      wineDir = "${inputs.nixpkgs}/pkgs/applications/emulators/wine/";
    in (
      (type == "directory" && (lib.hasPrefix path wineDir))
      || (type != "directory" && (lib.hasPrefix wineDir path))
    );
  };

  defaults = let
    sources = (import "${inputs.nixpkgs}/pkgs/applications/emulators/wine/sources.nix" {inherit pkgs;}).unstable;
  in {
    inherit supportFlags moltenvk;
    patches = [];
    buildScript = "${nixpkgs-wine}/pkgs/applications/emulators/wine/builder-wow.sh";
    configureFlags = ["--disable-tests"];
    geckos = with sources; [gecko32 gecko64];
    mingwGccs = with pkgsCross; [mingw32.buildPackages.gcc13 mingwW64.buildPackages.gcc13];
    monos = with sources; [mono];
    pkgArches = [pkgs pkgsi686Linux];
    platforms = ["x86_64-linux"];
    stdenv = overrideCC stdenv (wrapCCMulti gcc13);
    wineRelease = "unstable";
  };

  pnameGen = n: n + lib.optionalString (build == "full") "-full";
in {
  wine-ge = (callPackage "${nixpkgs-wine}/pkgs/applications/emulators/wine/base.nix" (defaults
    // {
      pname = pnameGen "wine-ge";
      version = pins.proton-wine.branch;
      src = pins.proton-wine;
    }))
    .overrideAttrs (old: {
    meta = old.meta // {passthru.updateScript = ./update-wine-ge.sh;};
  });

  wine-tkg = callPackage "${nixpkgs-wine}/pkgs/applications/emulators/wine/base.nix" (lib.recursiveUpdate defaults
    {
      pname = pnameGen "wine-tkg";
      version = lib.removeSuffix "\n" (lib.removePrefix "Wine version " (builtins.readFile ./wine-tkg/VERSION));
      src = pins.wine-tkg;
      monos = [wine-mono];
      stdenv = gccMultiStdenv;
      mingwGccs = with pkgsCross; [mingw32.buildPackages.gcc mingwW64.buildPackages.gcc];
    });

  wine-tkg-ntsync = callPackage "${nixpkgs-wine}/pkgs/applications/emulators/wine/base.nix" (lib.recursiveUpdate defaults
    {
      pname = pnameGen "wine-tkg-ntsync";
      version = lib.removeSuffix "\n" (lib.removePrefix "Wine version " (builtins.readFile ./wine-tkg-ntsync/VERSION));
      src = pins.wine-tkg-ntsync;
      monos = [wine-mono];
      stdenv = gccMultiStdenv;
      mingwGccs = with pkgsCross; [mingw32.buildPackages.gcc mingwW64.buildPackages.gcc];
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
    (callPackage "${nixpkgs-wine}/pkgs/applications/emulators/wine/base.nix" (defaults
      // rec {
        inherit version pname;
        src = fetchFromGitHub {
          owner = "wine-mirror";
          repo = "wine";
          rev = "wine-${version}";
          sha256 = "sha256-uDdjgibNGe8m1EEL7LGIkuFd1UUAFM21OgJpbfiVPJs=";
        };
        patches = ["${nixpkgs-wine}/pkgs/applications/emulators/wine/cert-path.patch"] ++ self.lib.mkPatches ./patches;
      }))
    .overrideDerivation (old: {
      nativeBuildInputs = with pkgs; [autoconf perl hexdump] ++ old.nativeBuildInputs;
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
