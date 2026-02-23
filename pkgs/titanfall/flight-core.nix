{
  appimageTools,
  lib,
  fetchurl,
  libthai,
  harfbuzz,
  fontconfig,
  freetype,
  libz,
  libX11,
  mesa,
  libdrm,
  fribidi,
  libxcb,
  libgpg-error,
  libGL,
  makeWrapper,
}:
let
  pname = "flight-core";
  version = "2.10.0";

  src = fetchurl {
    url = "https://github.com/R2NorthstarTools/FlightCore/releases/download/v${version}/${pname}_${version}_amd64.AppImage";
    hash = "sha256-TgPztA37Vbw9MXd+a5tnmKkePeJyNX7EO9pV7OFUU74=";
    name = "${pname}-${version}.AppImage";
  };

  appimageContents = appimageTools.extractType2 {
    name = "${pname}-${version}";
    inherit src;
  };

  libs = [
    libthai
    harfbuzz
    fontconfig
    freetype
    libz
    libX11
    mesa
    libdrm
    fribidi
    libxcb
    libgpg-error
    libGL
  ];
in
appimageTools.wrapType2 {
  inherit pname version src;
  multiPkgs = null; # no 32bit needed
  extraPkgs = p: (appimageTools.defaultFhsEnvArgs.multiPkgs p) ++ libs;
  extraInstallCommands = ''
    install -m 444 -D ${appimageContents}/${pname}.desktop -t $out/share/applications
    cp -r ${appimageContents}/usr/share/icons $out/share

    source "${makeWrapper}/nix-support/setup-hook" # cringe hack to get wrapProgram working in extraInstallCommands
    makeWrapper $out/bin/${pname}-${version} $out/bin/${pname} \
      --unset APPIMAGE \
      --unset APPDIR
  '';

  meta = {
    description = "Installer/Updater/Launcher for Northstar";
    homepage = "https://github.com/R2NorthstarTools/FlightCore";
    license = lib.licenses.mit;
    mainProgram = "flight-core";
    maintainers = with lib.maintainers; [ NotAShelf ];
    platforms = [ "x86_64-linux" ];
  };
}
