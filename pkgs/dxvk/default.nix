{
  # native inputs:
  lib,
  meson,
  ninja,
  glslang,
  # cross compile inputs:
  SDL2,
  windows,
  stdenv,
  pins,
}: let
  inherit (pins) dxvk dxvk-async;
in
  stdenv.mkDerivation {
    name = "dxvk";
    inherit (dxvk) version;

    enableParallelBuilding = true;
    separateDebugInfo = true;

    buildInputs =
      lib.optionals stdenv.targetPlatform.isWindows [windows.pthreads]
      ++ lib.optionals stdenv.targetPlatform.isLinux [SDL2];

    depsBuildBuild = [
      meson
      ninja
      glslang
    ];

    patches = [
      (dxvk-async + "/dxvk-async.patch")
    ];

    mesonFlags = ["--buildtype=release"];

    postInstall = lib.optionalString stdenv.targetPlatform.isWindows ''
      ln -s ${windows.mcfgthreads}/bin/mcfgthread-12.dll $out/bin/mcfgthread-12.dll
    '';

    src = dxvk;

    meta = with lib; {
      license = licenses.zlib;
      description = " Vulkan-based implementation of D3D9, D3D10 and D3D11 for Linux / Wine";
      homepage = "https://github.com/doitsujin/dxvk";
      maintainers = with lib.maintainers; [LunNova];
      platforms = platforms.linux ++ platforms.windows;
    };
  }
