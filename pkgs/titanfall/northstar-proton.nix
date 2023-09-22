{
  lib,
  autoPatchelfHook,
  fetchzip,
  gst_all_1,
  libmspack,
  libpcap,
  libpressureaudio,
  libudev-zero,
  libusb1,
  ocl-icd,
  stdenv,
}: let
  pname = "NorthstarProton";
  version = "8.1-1";

  src = fetchzip {
    url = "https://github.com/cyrv6737/${pname}/releases/download/v${version}/${pname}-${version}.tar.gz";
    hash = "sha256-xJecETwsCOcU+rGTTF9hpS3whgpwsY3WsasQWMTLyns=";
  };
in
  stdenv.mkDerivation {
    inherit pname version src;

    # Got errors about this file not being writable. It's supposed to be generated
    # by steampipe_fixups.py anyway, so we'll just omit it from the store.
    postUnpack = "rm source/steampipe_fixups.json";

    installPhase = "cp -r ./ $out";

    nativeBuildInputs = [autoPatchelfHook];

    # This lib isn't in nixpkgs, but it doesn't seem critical
    autoPatchelfIgnoreMissingDeps = ["liblatencyflex_layer.so"];

    buildInputs = [
      gst_all_1.gst-plugins-base
      libmspack
      libpcap
      libpressureaudio
      libudev-zero
      libusb1
      ocl-icd
    ];

    meta = {
      description = "A Proton build based on TKG's proton-tkg build system to run the Northstar client on Linux and SteamDeck";
      homepage = "https://github.com/cyrv6737/NorthstarProton";
      license = lib.licenses.mit;
      maintainers = with lib.maintainers; [NotAShelf];
      platforms = ["x86_64-linux"];
    };
  }
