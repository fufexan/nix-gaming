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

  installBakkesmod = writeShellScriptBin "install-bakkesmod" ''
    # Fetch bakkesmod installer and unzip it
    curl -L https://github.com/bakkesmodorg/BakkesModInjectorCpp/releases/latest/download/BakkesModSetup.zip --output ~/Downloads/BakkesModSetup.zip

    ${unzip}/bin/unzip ~/Downloads/BakkesModSetup.zip -d ~/Downloads/

    # Run the bakkesmod installer
    WINEPREFIX="${location}" ${wine}/bin/wine ~/Downloads/BakkesModSetup.exe

    # Clean up
    rm ~/Downloads/BakkesModSetup.zip
    rm ~/Downloads/BakkesModSetup.exe
    '';

  bakkesmodScript = writeShellScriptBin "bakkesmod" ''

    echo "bakkesmod exe path: ${bakkesmodExePath}"

    if [ ! -f "${bakkesmodExePath}" ]; then
        echo "${bakkesmodExePath} does not exist, installing bakkesmod..."
        ${installBakkesmod}/bin/install-bakkesmod
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

