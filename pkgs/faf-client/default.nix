{
  lib,
  stdenvNoCC,
  makeWrapper,
  makeDesktopItem,
  # regular jdk doesnt work due to problems with JavaFX even with .override { enableJavaFX = true; }
  openjdk17-bootstrap,
  xorg,
  libGL,
  gtk3,
  glib,
  alsa-lib,
  unstable ? false,
}: let
  pname = "faf-client";

  versionStable = "2023.5.0";
  sha256Stable = "0w26lplnfph8hs9jxvs4xa5rrx3jpbgl6vdk2w8qfpcgxv9ym8i6";
  srcStable = builtins.fetchTarball {
    url = "https://github.com/FAForever/downlords-faf-client/releases/download/v${versionStable}/faf_unix_${builtins.replaceStrings ["."] ["_"] versionStable}.tar.gz";
    sha256 = sha256Stable;
  };

  versionUnstable = "2023.6.0-alpha-1";
  sha256Unstable = "1n9rkgblmcs3pcm8fjf0k0pfbga7fkkal5mpf63m5i173i1x5fca";
  srcUnstable = builtins.fetchTarball {
    url = "https://github.com/FAForever/downlords-faf-client/releases/download/v${versionUnstable}/faf_unix_${builtins.replaceStrings ["."] ["_"] versionUnstable}.tar.gz";
    sha256 = sha256Unstable;
  };

  meta = with lib; {
    description = "Official client for Forged Alliance Forever";
    homepage = "https://github.com/FAForever/downlords-faf-client";
    license = licenses.mit;
  };

  icon = builtins.fetchurl {
    url = "https://github.com/FAForever/downlords-faf-client/raw/11f5d9a7a728883374510cdc0bec51c9aa4126d7/src/media/appicon/256.png";
    name = "faf-client.png";
    sha256 = "0zc2npsiqanw1kwm78n25g26f9f0avr9w05fd8aisk191zi7mj5r";
  };
  desktopItem = makeDesktopItem {
    inherit icon;
    name = "faf-client";
    exec = "faf-client";
    comment = meta.description;
    desktopName = "Forged Alliance Forever";
    categories = ["Game"];
    keywords = ["FAF" "Supreme Commander"];
  };

  libs = [
    alsa-lib
    glib
    gtk3.out
    libGL
    xorg.libXxf86vm
  ];
in
  stdenvNoCC.mkDerivation {
    inherit pname meta desktopItem;
    version =
      if unstable
      then versionUnstable
      else versionStable;
    src =
      if unstable
      then srcUnstable
      else srcStable;

    preferLocalBuild = true;
    nativeBuildInputs = [makeWrapper];

    installPhase = ''
      runHook preInstall

      mkdir -p $out
      cp -rfv * .install4j $out

      mkdir $out/bin
      makeWrapper $out/faf-client $out/bin/faf-client \
        --chdir $out \
        --set INSTALL4J_JAVA_HOME ${openjdk17-bootstrap} \
        --suffix LD_LIBRARY_PATH : ${lib.strings.makeLibraryPath libs}

      ln -s ../natives/faf-uid $out/lib/faf-uid
      ln -s ${./faf-client-setup.py} $out/bin/faf-client-setup

      mkdir $out/share
      cp -r ${desktopItem}/share/* $out/share/

      runHook postInstall
    '';

    passthru.updateScript = ./update.sh;
  }
