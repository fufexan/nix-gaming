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
  dieHook,
}: let
  pname = "viper";
  version = "1.12.1";

  capitalize = str: (lib.toUpper (builtins.substring 0 1 str)) + ((builtins.substring 1 (builtins.stringLength str)) str);

  src = fetchurl {
    url = "https://github.com/0neGal/${pname}/releases/download/v${version}/${capitalize pname}-${version}.AppImage";
    hash = "sha256-VjE3doKnEIS+N97yBz+NnNqHv9xQZb3yRD4hhhn6SKo=";
    name = "${pname}-${version}.AppImage";
  };

  appimageContents = appimageTools.extractType2 {
    inherit pname version src;
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

      # cringe hack to get wrapProgram working in extraInstallCommands
      source "${dieHook}/nix-support/setup-hook"
      source "${makeWrapper}/nix-support/setup-hook"

      mv $out/bin/${pname} $out/bin/${pname}-${version}
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
