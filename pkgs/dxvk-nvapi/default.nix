{
  lib,
  stdenv,
  pkg-config,
  vulkan-headers,
  ninja,
  meson,
  windows,
  pins,
}: let
  inherit (pins) dxvk-nvapi;
in
  # TODO: Add dxvk-nvapi-vkreflex-layer
  stdenv.mkDerivation {
    pname = "dxvk-nvapi";
    inherit (dxvk-nvapi) version;

    src = dxvk-nvapi;

    postPatch = ''
      # Use Vulkan Headers from nixpkgs
      substituteInPlace meson.build \
        --replace-fail "./external/Vulkan-Headers/include" "${vulkan-headers}/include"
    '';
    strictDeps = true;
    nativeBuildInputs = [
      pkg-config
      meson
      ninja
    ];
    buildInputs = lib.optional stdenv.hostPlatform.isWindows windows.pthreads;
    mesonBuildType = "release";
    doCheck = true;
    __structuredAttrs = true;

    meta = {
      description = "Alternative NVAPI implementation on top of DXVK";
      homepage = "https://github.com/jp7677/dxvk-nvapi";
      changelog = "https://github.com/jp7677/dxvk-nvapi/releases";
      license = lib.licenses.mit;
      badPlatforms = lib.platforms.darwin;
      platforms = lib.platforms.unix ++ lib.platforms.windows;
      maintainers = with lib.maintainers; [fuzen];
    };
  }
