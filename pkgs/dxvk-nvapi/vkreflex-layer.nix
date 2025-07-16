{
  lib,
  stdenv,
  pkg-config,
  vulkan-loader,
  ninja,
  meson,
  pins,
}: let
  inherit (pins) dxvk-nvapi;
in
  stdenv.mkDerivation {
    pname = "dxvk-nvapi-vkreflex-layer";
    version = lib.removePrefix "v" dxvk-nvapi.version;

    src = dxvk-nvapi;
    mesonFlags = ["./layer"];

    strictDeps = true;
    nativeBuildInputs = [
      pkg-config
      meson
      ninja
    ];
    buildInputs = [
      vulkan-loader
    ];
    mesonBuildType = "release";
    doCheck = true;

    meta = {
      description = "Alternative NVAPI implementation on top of DXVK";
      homepage = "https://github.com/jp7677/dxvk-nvapi";
      changelog = "https://github.com/jp7677/dxvk-nvapi/releases";
      license = lib.licenses.mit;
      badPlatforms = lib.platforms.darwin;
      platforms = lib.platforms.unix;
    };
  }
