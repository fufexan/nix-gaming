{
  # native inputs:
  lib,
  fetchFromGitHub,
  meson,
  ninja,
  glslang,
  wine64,
  # cross compile inputs:
  stdenv,
  windows,
}:
stdenv.mkDerivation rec {
  pname = "vkd3d-proton";
  version = "2.7";

  enableParallelBuilding = true;
  separateDebugInfo = true;

  src = fetchFromGitHub {
    owner = "HansKristian-Work";
    repo = "vkd3d-proton";
    rev = "v${version}";
    fetchSubmodules = true;
    hash = "sha256-FlH0t1DO01CCLdvH0U/IXgUq1gFpc4krEbu/Tlv/pLI=";
  };

  buildInputs = lib.optionals stdenv.targetPlatform.isWindows [
    windows.mcfgthreads
    windows.pthreads
  ];

  depsBuildBuild = [
    meson
    ninja
    glslang
    wine64
  ];

  strictDeps = true;

  patches = [
    # Fixes a compiler error with mingw
    ./explicitly_define_hex_base.patch
  ];

  postInstall = lib.optionalString stdenv.targetPlatform.isWindows ''
    ln -s ${windows.mcfgthreads}/bin/mcfgthread-12.dll $out/bin/mcfgthread-12.dll
  '';

  mesonFlags =
    [
      "--buildtype=release"
    ]
    # nix's cross compile already sets up most things correctly so the cross-file shouldn't be needed
    # however vkd3d-proton relies on the cross-file to set up static build flags
    # so if we don't use it the resulting dlls will try to link to libstdc++ as a dll
    # and that doesn't work since it isn't built as one and won't be in the wine prefix
    ++ lib.optionals (stdenv.targetPlatform.system == "x86_64-windows") ["--cross-file build-win64.txt"]
    ++ lib.optionals (stdenv.targetPlatform.system == "i686-windows") ["--cross-file build-win32.txt"];

  meta = with lib; {
    license = licenses.lgpl21;
    description = "VKD3D-Proton is a fork of VKD3D, which aims to implement the full Direct3D 12 API on top of Vulkan. The project serves as the development effort for Direct3D 12 support in Proton.";
    homepage = "https://github.com/HansKristian-Work/vkd3d-proton";
    maintainers = with lib.maintainers; [LunNova];
    platforms = platforms.linux ++ platforms.windows;
  };
}
