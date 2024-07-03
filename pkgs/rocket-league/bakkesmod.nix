{
  lib,
  makeDesktopItem,
  symlinkJoin,
  writeShellScriptBin,
  unzip,
  wine,
  pname ? "rocket-league",
  location ? "$HOME/Games/${pname}",
}: let

  bakkesmodIcon = builtins.fetchurl {
    url = "https://bp-prod.nyc3.digitaloceanspaces.com/site-assets/static/bm-transparent.png";
    name = "bakkesmod.png";
    sha256 = "18n6hcab25n9i4v2vmq6p8v7ii17p4x9i9jx3b300lfqm56239y7";
  };

  bakkesmodExePath = "${location}/drive_c/Program Files/BakkesMod/BakkesMod.exe";

  bakkesmodInstaller = writeShellScriptBin "install-bakkesmod" ''
    # Create a temp dir for the installer file
    export TEMP_DIR=$(mktemp -d)

    # Fetch bakkesmod installer and unzip it
    curl -L https://github.com/bakkesmodorg/BakkesModInjectorCpp/releases/latest/download/BakkesModSetup.zip --output $TEMP_DIR/BakkesModSetup.zip

    ${unzip}/bin/unzip $TEMP_DIR/BakkesModSetup.zip -d $TEMP_DIR

    # Run the bakkesmod installer
    WINEPREFIX="${location}" ${wine}/bin/wine $TEMP_DIR/BakkesModSetup.exe

    # Clean up
    rm $TEMP_DIR/BakkesModSetup.zip
    rm $TEMP_DIR/BakkesModSetup.exe
    '';

  bakkesmodScript = writeShellScriptBin "bakkesmod" ''

    echo "bakkesmod exe path: ${bakkesmodExePath}"

    if [ ! -f "${bakkesmodExePath}" ]; then
        echo "${bakkesmodExePath} does not exist, installing bakkesmod..."
        ${bakkesmodInstaller}/bin/install-bakkesmod
        echo "done installing, run 'bakkesmod' again to start bakkesmod"
        exit 0
    fi

    WINEPREFIX="${location}" WINEFSYNC=1 ${wine}/bin/wine c:/Program\ Files/BakkesMod/BakkesMod.exe

    '';

  bakkesmodDesktopItem = makeDesktopItem {
    name = "bakkesmod";
    exec = "${bakkesmodScript}/bin/bakkesmod";
    icon = bakkesmodIcon;
    desktopName = "Bakkesmod (Rocket League mod)";
    categories = ["Game"];
  };

in 
  symlinkJoin {
    name = "bakkesmod";
    paths = [bakkesmodDesktopItem bakkesmodScript];

    meta = {
      description = "Rocket League mod";
      homepage = "https://www.bakkesmod.com";
      platforms = ["x86_64-linux"];
    };
  }

