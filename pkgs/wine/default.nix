{
  self,
  pins,
  lib,
  build,
  pkgs,
  pkgsCross,
  pkgsi686Linux,
  callPackage,
  fetchFromGitHub,
  fetchurl,
  replaceVars,
  moltenvk,
  supportFlags,
  overrideCC,
  wrapCCMulti,
  gcc13,
  stdenv,
  wine-mono,
}: let
  nixpkgs-wine = pkgs.path;

  defaults = let
    sources =
      (import (nixpkgs-wine + "/pkgs/applications/emulators/wine/sources.nix") {inherit pkgs;})
        .unstable;
  in {
    inherit supportFlags moltenvk;
    patches = [];
    buildScript = replaceVars (nixpkgs-wine + "/pkgs/applications/emulators/wine/builder-wow.sh") {
      pkgconfig64remove = lib.makeSearchPathOutput "dev" "lib/pkgconfig" [
        pkgs.glib
        pkgs.gst_all_1.gstreamer
      ];
    };
    configureFlags = ["--disable-tests"];
    geckos = with sources; [
      gecko32
      gecko64
    ];
    mingwGccs = with pkgsCross; [
      mingw32.buildPackages.gcc13
      mingwW64.buildPackages.gcc13
    ];
    monos = with sources; [mono];
    pkgArches = [
      pkgs
      pkgsi686Linux
    ];
    platforms = ["x86_64-linux"];
    stdenv = overrideCC stdenv (wrapCCMulti gcc13);
    useStaging = false;
    mainProgram = "wine64";
  };

  # defaults for newer WoW64 builds
  defaultsWow64 = lib.recursiveUpdate (removeAttrs defaults ["buildScript"]) {
    configureFlags = [
      "--disable-tests"
      "--enable-archs=x86_64,i386"
    ];
    mingwGccs = with pkgsCross; [
      mingw32.buildPackages.gcc
      mingwW64.buildPackages.gcc
    ];
    monos = [wine-mono];
    pkgArches = [pkgs];
    inherit stdenv;
    mainProgram = "wine";
  };

  pnameGen = n: n + lib.optionalString (build == "full") "-full";
in {
  wine-cachyos =
    (callPackage (nixpkgs-wine + "/pkgs/applications/emulators/wine/base.nix") (
      lib.recursiveUpdate defaultsWow64 {
        pname = pnameGen "wine-cachyos";
        version = lib.removeSuffix "-wine" (lib.removePrefix "cachyos-" pins.wine-cachyos.version);
        src = pins.wine-cachyos;
      }
    ))
    # https://github.com/CachyOS/CachyOS-PKGBUILDS/blob/b76138d70274f3ba6f7e0f7ca62fa2e335b93ad6/wine-cachyos/PKGBUILD#L116
    .overrideAttrs
    (
      _final: prev: {
        nativeBuildInputs = with pkgs;
          [
            autoreconfHook
            python3
            perl
          ]
          ++ prev.nativeBuildInputs;
        preAutoreconf = ''
          patchShebangs --build tools/make_requests tools/make_specfiles dlls/winevulkan/make_vulkan
          tools/make_requests
          tools/make_specfiles
          XDG_CACHE_HOME=$(mktemp -d) dlls/winevulkan/make_vulkan -x vk.xml -X video.xml
        '';
      }
    );

  wine-ge =
    (callPackage (nixpkgs-wine + "/pkgs/applications/emulators/wine/base.nix") (
      defaults
      // {
        pname = pnameGen "wine-ge";
        version = pins.proton-wine.branch;
        src = pins.proton-wine;
      }
    )).overrideAttrs
    (old: {
      meta =
        old.meta
        // {
          passthru.updateScript = ./update-wine-ge.sh;
        };
    });

  wine-tkg = callPackage (nixpkgs-wine + "/pkgs/applications/emulators/wine/base.nix") (
    lib.recursiveUpdate defaultsWow64 {
      pname = pnameGen "wine-tkg";
      version = lib.removeSuffix "\n" (
        lib.removePrefix "Wine version " (builtins.readFile ./wine-tkg/VERSION)
      );
      src = pins.wine-tkg;
    }
  );

  wine-osu = let
    pname = pnameGen "wine-osu";
    version = "10.15";
    staging = fetchFromGitHub {
      owner = "wine-staging";
      repo = "wine-staging";
      rev = "v${version}";
      sha256 = "sha256-VzHM4Qm0XDP7suCT5dmJgoDJmZ1DLg6qqOUVQzNc0g4=";
    };
  in
    (callPackage (nixpkgs-wine + "/pkgs/applications/emulators/wine/base.nix") (
      lib.recursiveUpdate defaultsWow64 {
        inherit version pname;
        src = fetchurl {
          url = "https://dl.winehq.org/wine/source/10.x/wine-${version}.tar.xz";
          hash = "sha256-MH4hI3xui96iZvlG0x8J7SexlX35oDUW2Ccf0T4cJh0=";
        };
        patches = [
          (nixpkgs-wine + "/pkgs/applications/emulators/wine/cert-path.patch")
        ] ++ self.lib.mkPatches pins.wine-osu-patches [];
      }
    )).overrideDerivation
    (old: {
      nativeBuildInputs = with pkgs;
        [
          autoconf
          autoreconfHook
          gitMinimal
          hexdump
          nasm
          perl
          python3
        ]
        ++ old.nativeBuildInputs;
      buildInputs = with pkgs; [
        autoconf
        perl
        gitMinimal
      ] ++ old.buildInputs;

      NIX_CFLAGS_COMPILE = "-Wno-incompatible-pointer-types";

      prePatch = ''
        patchShebangs tools
        cp -r ${staging}/{patches,staging} .
        chmod +w patches
        patchShebangs ./patches/gitapply.sh
        python3 ./staging/patchinstall.py DESTDIR="$PWD" --no-autoconf --all ${builtins.readFile "${pins.wine-osu-patches}/staging-exclude"}
      '';

      postPatch = ''
        ./tools/make_requests
      '';
    });
}
