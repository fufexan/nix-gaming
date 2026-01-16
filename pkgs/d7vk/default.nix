{
  lib,
  # native inputs:
  meson,
  ninja,
  glslang,
  python3,
  pins,
  windows,
  stdenv,
}: let
  inherit (pins) d7vk;
in
  stdenv.mkDerivation {
    name = "d7vk";
    version = lib.removePrefix "v" d7vk.version;
    src = d7vk;

    separateDebugInfo = true;

    nativeBuildInputs = [
      python3
    ];

    buildInputs =
      lib.optionals stdenv.targetPlatform.isWindows [windows.pthreads];

    depsBuildBuild = [
      meson
      ninja
      glslang
    ];

    postPatch = ''
      patchShebangs ./
    '';

    mesonFlags = [
      "--buildtype=release"
    ];

    meta = with lib; {
      license = licenses.zlib;
      description = "Vulkan-based implementation of D3D7, 6 and 5 for Linux / Wine, spun off from DXVK";
      homepage = "https://github.com/WinterSnowfall/d7vk";
      maintainers = with lib.maintainers; [ccicnce113424];
      platforms = platforms.windows;
      # GCC <13 ends up with an extra dep on mcfg-thread12
      broken = stdenv.cc.isGNU && lib.versionOlder stdenv.cc.version "13";
    };
  }
