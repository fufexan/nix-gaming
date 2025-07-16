{
  # native inputs:
  lib,
  meson,
  ninja,
  glslang,
  wine64,
  # cross compile inputs:
  stdenv,
  windows,
  pins,
}:
stdenv.mkDerivation {
  pname = "vkd3d-proton";
  version = lib.removePrefix "v" pins.vkd3d-proton.version;

  enableParallelBuilding = true;
  separateDebugInfo = true;

  src = pins.vkd3d-proton;

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

  # Manually pass pinned version info through to vcs_tag since we don't have .git
  postPatch = ''
    substituteInPlace meson.build \
      --replace-fail "'git', 'describe', '--always', '--exclude=*', '--abbrev=15', '--dirty=0'" \
      "'echo', '${builtins.substring 0 15 pins.vkd3d-proton.revision}'" \
      --replace-fail "'git', 'describe', '--always', '--tags', '--dirty=+'" \
      "'echo', '${pins.vkd3d-proton.version}'"
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
    # GCC <13 ends up with an extra dep on mcfg-thread12
    broken = stdenv.cc.isGNU && lib.versionOlder stdenv.cc.version "13";
  };
}
