# https://modrinth.com/app
{
  lib,
  stdenvNoCC,
  fetchurl,
  dpkg,
  autoPatchelfHook,
  wrapGAppsHook,
  gtk3,
  webkitgtk_4_0,
  glib-networking,
  openssl_1_1,
  jdk17,
  openal,
  libpulseaudio,
}:
stdenvNoCC.mkDerivation rec {
  pname = "modrinth-app";
  version = "0.5.4";

  src = fetchurl {
    url = "https://launcher-files.modrinth.com/versions/${version}/linux/${pname}_${version}_amd64.deb";
    hash = "sha256-CW6RQ89LlKbSq6lL1CWQmO0PmbSl7NtUiX3rrn/6U10=";
  };

  unpackPhase = ''
    runHook preUnpack
    dpkg-deb -x $src .
    runHook postUnpack
  '';

  nativeBuildInputs = [dpkg autoPatchelfHook wrapGAppsHook];
  buildInputs = [gtk3 webkitgtk_4_0 glib-networking openssl_1_1];

  installPhase = ''
    runHook preInstall
    mv -v usr $out
    runHook postInstall
  '';

  preFixup = ''
    gappsWrapperArgs+=(
      --prefix PATH : ${lib.makeSearchPath "bin/java" [jdk17]}
      --set LD_LIBRARY_PATH ${lib.makeLibraryPath [openal libpulseaudio]}
    )
  '';
}
