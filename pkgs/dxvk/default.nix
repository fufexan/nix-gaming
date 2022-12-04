{
  # native inputs:
  fetchFromGitHub,
  lib,
  meson,
  ninja,
  glslang,
  # cross compile inputs:
  SDL2,
  windows,
  stdenv,
}: let
  version = "2.0";
  dxvk-async = fetchFromGitHub {
    owner = "Sporif";
    repo = "dxvk-async";
    rev = version;
    hash = "sha256-meXii3aWKG2FM8FABaLC9Wo9DG+detr+HtDkmO1nuyw=";
  };
in
  stdenv.mkDerivation rec {
    name = "dxvk";
    inherit version;

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

    src = fetchFromGitHub {
      owner = "doitsujin";
      repo = "dxvk";
      rev = "v" + version;
      fetchSubmodules = true;
      hash = "sha256-mSNFvoILsvm+CpWV7uRlb7DkjV7ctClSUdteNcF5EAY=";
    };

    meta = with lib; {
      license = licenses.zlib;
      description = " Vulkan-based implementation of D3D9, D3D10 and D3D11 for Linux / Wine";
      homepage = "https://github.com/doitsujin/dxvk";
      maintainers = with lib.maintainers; [LunNova];
      platforms = platforms.linux ++ platforms.windows;
    };
  }
