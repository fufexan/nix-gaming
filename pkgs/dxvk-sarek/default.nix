{
  lib,
  meson,
  ninja,
  glslang,
  windows,
  stdenv,
  pins,
}:
let
  inherit (pins) dxvk-sarek;
in
stdenv.mkDerivation {
  pname = "dxvk-sarek";
  version = lib.removePrefix "v" dxvk-sarek.version;
  src = dxvk-sarek;

  nativeBuildInputs = [
    meson
    ninja
    glslang
  ];

  buildInputs = [ windows.pthreads ];

  strictDeps = true;
  __structuredAttrs = true;

  meta = {
    license = lib.licenses.zlib;
    description = "Vulkan-based implementation of D3D3, 5, 6, 7, 8, 9, 10 and 11 for Linux/Wine without needing Vulkan 1.3";
    homepage = "https://github.com/pythonlover02/DXVK-Sarek";
    maintainers = with lib.maintainers; [ ccicnce113424 ];
    platforms = lib.platforms.windows;
    # GCC <13 ends up with an extra dep on mcfg-thread12
    broken = stdenv.cc.isGNU && lib.versionOlder stdenv.cc.version "13";
  };
}
