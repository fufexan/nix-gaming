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
  withSdl3 ? (!stdenv.hostPlatform.isWindows),
  sdl3,
  withSdl2 ? (!stdenv.hostPlatform.isWindows),
  SDL2,
  withGlfw ? (!stdenv.hostPlatform.isWindows),
  glfw,
  windows,
  stdenv,
}:
let
  inherit (pins) dxvk dxvk-gplasync;

  inherit (stdenv) hostPlatform;
  libPrefix = lib.optionalString (!hostPlatform.isWindows) "lib";
  soVersion =
    version:
    if hostPlatform.isDarwin then
      ".${version}${hostPlatform.extensions.sharedLibrary}"
    else if hostPlatform.isWindows then
      hostPlatform.extensions.sharedLibrary
    else
      "${hostPlatform.extensions.sharedLibrary}.${version}";

  libglfw = "${libPrefix}glfw${soVersion "3"}";
  libSDL2 = "${libPrefix}SDL2${lib.optionalString (!hostPlatform.isWindows) "-2.0"}${soVersion "0"}";
  libsdl3 = "${libPrefix}SDL3${soVersion "0"}";
in
stdenv.mkDerivation (finalAttrs: {
  pname = "dxvk";
  version = lib.removePrefix "v" dxvk.version;
  src = dxvk;

  separateDebugInfo = true;

  nativeBuildInputs = [
    python3
  ]
  ++ lib.optional withSdl3 sdl3
  ++ lib.optional withSdl2 SDL2
  ++ lib.optional withGlfw glfw;

  buildInputs =
    lib.optionals stdenv.targetPlatform.isWindows [ windows.pthreads ] ++ lib.optional withGlfw glfw;

  depsBuildBuild = [
    meson
    ninja
    glslang
  ]
  ++ lib.optional (!stdenv.targetPlatform.isWindows) pkg-config;

  strictDeps = true;
  __structuredAttrs = true;

  postPatch = ''
    patchShebangs ./
  ''
  + lib.optionalString (lib.versionOlder finalAttrs.version "3.0") ''
    substituteInPlace meson.build \
      --replace-fail "dependency('glfw'" "dependency('glfw3'"
  ''
  + lib.optionalString withGlfw ''
    substituteInPlace src/wsi/glfw/wsi_platform_glfw.cpp \
      --replace-fail '${libglfw}' '${lib.getLib glfw}/lib/${libglfw}'
  ''
  + lib.optionalString withSdl2 ''
    substituteInPlace src/wsi/sdl2/wsi_platform_sdl2.cpp \
      --replace-fail '${libSDL2}' '${lib.getLib SDL2}/lib/${libSDL2}'
  ''
  + lib.optionalString withSdl3 ''
    substituteInPlace src/wsi/sdl3/wsi_platform_sdl3.cpp \
      --replace-fail '${libsdl3}' '${lib.getLib sdl3}/lib/${libsdl3}'
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

  meta = {
    license = lib.licenses.zlib;
    description = "Vulkan-based implementation of D3D8, D3D9, D3D10 and D3D11 for Linux / Wine";
    homepage = "https://github.com/doitsujin/dxvk";
    maintainers = with lib.maintainers; [ LunNova ];
    platforms = lib.platforms.linux ++ lib.platforms.windows;
    # GCC <13 ends up with an extra dep on mcfg-thread12
    broken = stdenv.cc.isGNU && lib.versionOlder stdenv.cc.version "13";
  };
})
