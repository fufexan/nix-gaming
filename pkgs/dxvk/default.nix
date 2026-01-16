{
  lib,
  # Enable an async patch, currently dxvk-gplasync
  withAsync ? true,
  # native inputs:
  meson,
  ninja,
  pkg-config,
  glslang,
  python3,
  pins,
  # cross compile inputs:
  withSdl3 ? true,
  sdl3,
  withSdl2 ? true,
  SDL2,
  withGlfw ? true,
  glfw,
  windows,
  stdenv,
}: let
  inherit (pins) dxvk dxvk-gplasync;
in
  stdenv.mkDerivation {
    name = "dxvk";
    version = lib.removePrefix "v" dxvk.version;
    src = dxvk;

    separateDebugInfo = true;

    nativeBuildInputs = [
      python3
    ];

    buildInputs =
      lib.optionals stdenv.targetPlatform.isWindows [windows.pthreads]
      ++ lib.optionals stdenv.targetPlatform.isLinux (
        lib.optional withSdl3 sdl3 ++ lib.optional withSdl2 SDL2 ++ lib.optional withGlfw glfw
      );

    depsBuildBuild =
      [
        meson
        ninja
        glslang
      ]
      ++ lib.optional (!stdenv.targetPlatform.isWindows) pkg-config;

    postPatch =
      ''
        patchShebangs ./
      ''
      # https://aur.archlinux.org/cgit/aur.git/tree/PKGBUILD?h=libdxvk-gplasync#n46
      + lib.optionalString (stdenv.targetPlatform.isLinux && withGlfw) ''
        substituteInPlace meson.build \
          --replace-warn "'glfw'" "'glfw3'"
      '';

    patches = lib.optionals withAsync [
      (dxvk-gplasync + "/patches/dxvk-gplasync-${lib.removePrefix "v" dxvk-gplasync.version}.patch")
      (dxvk-gplasync + "/patches/global-dxvk.conf.patch")
    ];

    mesonFlags = [
      "--buildtype=release"
      (lib.mesonEnable "native_sdl3" withSdl3)
      (lib.mesonEnable "native_sdl2" withSdl2)
      (lib.mesonEnable "native_glfw" withGlfw)
    ];

    meta = with lib; {
      license = licenses.zlib;
      description = "Vulkan-based implementation of D3D8, D3D9, D3D10 and D3D11 for Linux / Wine";
      homepage = "https://github.com/doitsujin/dxvk";
      maintainers = with lib.maintainers; [LunNova];
      platforms = platforms.linux ++ platforms.windows;
      # GCC <13 ends up with an extra dep on mcfg-thread12
      broken = stdenv.cc.isGNU && lib.versionOlder stdenv.cc.version "13";
    };
  }
