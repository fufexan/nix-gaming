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
}: let
  pname = "viper";
  version = "1.8.5";

  src = fetchurl {
    url = "https://github.com/0neGal/${pname}/releases/download/v${version}/${pname}-${version}.AppImage";
    hash = "sha256-jFroi4j2kNEGGU6R9WUvRK+vy26eizjPsZ6Cq6uLe0I=";
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
      description = "Launcher+Updater for TF|2 Northstar ";
      homepage = "https://github.com/0neGal/viper";
      license = lib.licenses.gpl3Only;
      mainProgram = "viper";
      maintainers = with lib.maintainers; [NotAShelf];
      platforms = ["x86_64-linux"];
    };
  }
