{
  lib,
  stdenv,
  cmake,
  ninja,
  vulkan-headers,
  vulkan-loader,
  vulkan-utility-libraries,
  pins,
}:
let
  inherit (pins) low_latency_layer;
in
stdenv.mkDerivation {
  pname = "low_latency_layer";
  version = lib.removePrefix "v" low_latency_layer.version;
  src = low_latency_layer;

  nativeBuildInputs = [
    cmake
    ninja
  ];

  buildInputs = [
    vulkan-headers
    vulkan-loader
    vulkan-utility-libraries
  ];

  separateDebugInfo = true;

  strictDeps = true;
  __structuredAttrs = true;

  meta = {
    description = "Vulkan layer for hardware agnostic input latency reduction ";
    homepage = "https://github.com/Korthos-Software/low_latency_layer";
    changelog = "https://github.com/Korthos-Software/low_latency_layer/releases/tag/${low_latency_layer.version}";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ ccicnce113424 ];
  };
}
