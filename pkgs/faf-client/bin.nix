{
  lib,
  stdenvNoCC,
  makeWrapper,
  makeDesktopItem,
  openjdk21,
  xorg,
  libGL,
  gtk3,
  glib,
  alsa-lib,
  fontconfig,
  freetype,
  pango,
  unstable ? false,
}: let
  pname = "faf-client-bin";

  versionStable = "2024.6.2";
  sha256Stable = "0hqrxjxcs367i4r9i2kc42y3y6qqdm7lj0i1haz4q6891h4x22w9";
  srcStable = builtins.fetchTarball {
    url = "https://github.com/FAForever/downlords-faf-client/releases/download/v${versionStable}/faf_unix_${builtins.replaceStrings ["."] ["_"] versionStable}.tar.gz";
    sha256 = sha256Stable;
  };

  versionUnstable = "2024.6.2";
  sha256Unstable = "0hqrxjxcs367i4r9i2kc42y3y6qqdm7lj0i1haz4q6891h4x22w9";
  srcUnstable = builtins.fetchTarball {
    url = "https://github.com/FAForever/downlords-faf-client/releases/download/v${versionUnstable}/faf_unix_${builtins.replaceStrings ["."] ["_"] versionUnstable}.tar.gz";
    sha256 = sha256Unstable;
  };

  meta = with lib; {
    description = "Official client for Forged Alliance Forever";
    homepage = "https://github.com/FAForever/downlords-faf-client";
    license = licenses.mit;
    maintainers = with maintainers; [chayleaf];
  };

  icon = "faf-client";
  iconHashes = {
    "256" = "0zc2npsiqanw1kwm78n25g26f9f0avr9w05fd8aisk191zi7mj5r";
    "128" = "0gcxvvxpkrjrxz43jjw71pmppap361zzz76pad5slqyl5p506n1a";
    "64" = "09mi8k36xzk0sfp1wfzhhzavnwgwki4ziidjkv9z3p5vb6vkdc6j";
    "48" = "1kgjgk4h02nlwrwqf5l4laww28sgz3ywrzffkx1zzwwwxdfxb2fc";
    "32" = "1ra5b1z6f39f7mdnphz6v6lkxfjpw56k44z91mn1n58pvkzdf22r";
    "16" = "0sp7k88h1kq6bz8rvz8hyd9dgxbl5db6q1f9ypg3dkg03fh53rjw";
  };
  icons = builtins.mapAttrs (k: v:
    builtins.fetchurl {
      name = "faf-client-${k}.png";
      url = "https://github.com/FAForever/downlords-faf-client/raw/11f5d9a7a728883374510cdc0bec51c9aa4126d7/src/media/appicon/${k}.png";
      sha256 = v;
    })
  iconHashes;
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
    fontconfig
    freetype
    glib
    gtk3
    libGL
    pango
    xorg.libX11
    xorg.libXtst
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

      mkdir -p $out/lib/faf-client
      cp -rfv * .install4j $out/lib/faf-client

      mkdir $out/bin
      makeWrapper $out/lib/faf-client/faf-client $out/bin/faf-client \
        --chdir $out/lib/faf-client \
        --set-default INSTALL4J_ADD_VM_PARAMS '~/.cache/openjfx' \
        --set-default LOG_DIR '~/.faforever/logs' \
        --set INSTALL4J_JAVA_HOME ${openjdk21} \
        --suffix LD_LIBRARY_PATH : ${lib.makeLibraryPath libs}
      sed -i "s#'~/.faforever/logs'#"'"$HOME/.faforever/logs"#' $out/bin/faf-client
      sed -i "s#'~/.cache/openjfx'#"'"-Djavafx.cachedir=''${XDG_CACHE_HOME:-$HOME/.cache}/openjfx"#' $out/bin/faf-client

      rm $out/lib/faf-client/natives/faf-uid.exe
      ln -s ../natives/faf-uid $out/lib/faf-client/lib/faf-uid
      ln -s ../natives/faf-ice-adapter.jar $out/lib/faf-client/lib/faf-ice-adapter.jar
      cp ${./faf-client-setup.py} $out/bin/faf-client-setup
      chmod +x $out/bin/faf-client-setup

      mkdir $out/share
      cp -r ${desktopItem}/share/* $out/share/
      ${
        lib.concatStringsSep "\n" (lib.mapAttrsToList (res: file: let
            dir = "$out/share/icons/hicolor/${res}x${res}/apps";
          in ''
            mkdir -p ${dir}
            cp ${file} ${dir}/${icon}.png
          '')
          icons)
      }

      runHook postInstall
    '';

    passthru.updateScript = ./update.sh;
  }
