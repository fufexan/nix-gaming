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
  replaceVars,
  moltenvk,
  supportFlags,
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
    sources = (import "${nixpkgs-wine}/pkgs/applications/emulators/wine/sources.nix" {inherit pkgs;}).unstable;
  in {
    inherit supportFlags moltenvk;
    patches = [];
    buildScript = replaceVars "${nixpkgs-wine}/pkgs/applications/emulators/wine/builder-wow.sh" {
      pkgconfig64remove = lib.makeSearchPathOutput "dev" "lib/pkgconfig" [pkgs.glib pkgs.gst_all_1.gstreamer];
    };
    configureFlags = ["--disable-tests"];
    geckos = with sources; [gecko32 gecko64];
    mingwGccs = with pkgsCross; [mingw32.buildPackages.gcc13 mingwW64.buildPackages.gcc13];
    monos = with sources; [mono];
    pkgArches = [pkgs pkgsi686Linux];
    platforms = ["x86_64-linux"];
    stdenv = overrideCC stdenv (wrapCCMulti gcc13);
    wineRelease = "unstable";
    mainProgram = "wine64";
  };

  # defaults for newer WoW64 builds
  defaultsWow64 = lib.recursiveUpdate defaults {
    buildScript = null;
    configureFlags = ["--disable-tests" "--enable-archs=x86_64,i386"];
    mingwGccs = with pkgsCross; [mingw32.buildPackages.gcc mingwW64.buildPackages.gcc];
    monos = [wine-mono];
    pkgArches = [pkgs];
    inherit stdenv;
    mainProgram = "wine";
  };

  pnameGen = n: n + lib.optionalString (build == "full") "-full";
in {
  wine-cachyos =
    (callPackage "${nixpkgs-wine}/pkgs/applications/emulators/wine/base.nix" (lib.recursiveUpdate defaultsWow64 {
      pname = pnameGen "wine-cachyos";
      version = lib.removeSuffix "-wine" (lib.removePrefix "cachyos-" pins.wine-cachyos.version);
      src = pins.wine-cachyos;
    }))
    # https://github.com/CachyOS/CachyOS-PKGBUILDS/blob/b76138d70274f3ba6f7e0f7ca62fa2e335b93ad6/wine-cachyos/PKGBUILD#L116
    .overrideAttrs (_final: prev: {
      nativeBuildInputs = with pkgs; [autoreconfHook python3 perl] ++ prev.nativeBuildInputs;
      preAutoreconf = ''
        patchShebangs --build tools/make_requests tools/make_specfiles dlls/winevulkan/make_vulkan
        tools/make_requests
        tools/make_specfiles
        XDG_CACHE_HOME=$(mktemp -d) dlls/winevulkan/make_vulkan -x vk.xml -X video.xml
      '';
    });

  wine-ge = (callPackage "${nixpkgs-wine}/pkgs/applications/emulators/wine/base.nix" (defaults
    // {
      pname = pnameGen "wine-ge";
      version = pins.proton-wine.branch;
      src = pins.proton-wine;
    }))
    .overrideAttrs (old: {
    meta = old.meta // {passthru.updateScript = ./update-wine-ge.sh;};
  });

  wine-tkg = callPackage "${nixpkgs-wine}/pkgs/applications/emulators/wine/base.nix" (lib.recursiveUpdate defaultsWow64
    {
      pname = pnameGen "wine-tkg";
      version = lib.removeSuffix "\n" (lib.removePrefix "Wine version " (builtins.readFile ./wine-tkg/VERSION));
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
