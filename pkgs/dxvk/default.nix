{
  lib,
  # Enable an async patch, currently dxvk-gplasync
  withAsync ? true,
  # native inputs:
  meson,
  ninja,
  glslang,
  python3,
  pins,
  # cross compile inputs:
  SDL2,
  windows,
  stdenv,
}: let
  inherit (pins) dxvk dxvk-gplasync;
in
  stdenv.mkDerivation {
    name = "dxvk";
    inherit (dxvk) version;

    enableParallelBuilding = true;
    separateDebugInfo = true;

    nativeBuildInputs = [
      python3
    ];

    buildInputs =
      lib.optionals stdenv.targetPlatform.isWindows [windows.pthreads]
      ++ lib.optionals stdenv.targetPlatform.isLinux [SDL2];

    postPatch = ''
      patchShebangs ./
    '';

    depsBuildBuild = [
      meson
      ninja
      glslang
    ];

    patches = lib.optionals withAsync [
      (dxvk-gplasync + "/patches/dxvk-gplasync-${lib.removePrefix "v" dxvk-gplasync.version}.patch")
      (dxvk-gplasync + "/patches/global-dxvk.conf.patch")
    ];

    mesonFlags = ["--buildtype=release"];

    src = dxvk;

    meta = with lib; {
      license = licenses.zlib;
      description = " Vulkan-based implementation of D3D9, D3D10 and D3D11 for Linux / Wine";
      homepage = "https://github.com/doitsujin/dxvk";
      maintainers = with lib.maintainers; [LunNova];
      platforms = platforms.linux ++ platforms.windows;
      # GCC <13 ends up with an extra dep on mcfg-thread12
      broken = stdenv.cc.isGNU && lib.versionOlder stdenv.cc.version "13";
    };
  }
