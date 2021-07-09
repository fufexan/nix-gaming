{ lib
, makeDesktopItem
, symlinkJoin
, wine ? null
, winestreamproxy
, winetricks
, writeShellScriptBin

, location ? "$HOME/.osu"
, pname ? "osu-stable"
, tricks ? [ "gdiplus" "dotnet40" "meiryo" ]
, verbose ? false
, wineFlags ? ""
}:

let
  osusrc = builtins.fetchurl {
    url = "https://m1.ppy.sh/r/osu!install.exe";
    name = "osuinstall.exe";
    sha256 = "sha256-Cr8/FRoPv+q9uL+fBJFeaM0oQ1ROzHJxPM661gT+MKM=";
  };
  osuicon = builtins.fetchurl {
    url = "https://i.ppy.sh/013ed2c11b34720790e74035d9f49078d5e9aa64/68747470733a2f2f6f73752e7070792e73682f77696b692f696d616765732f4272616e645f6964656e746974795f67756964656c696e65732f696d672f75736167652d66756c6c2d636f6c6f75722e706e67";
    name = "osu.png";
    sha256 = "sha256-TwaRVz2gl7TBqA9JcvG51bNVVlI7Xkc/l3VtoDXE2W8=";
  };

  # concat winetricks args
  tricksFmt = with builtins;
    if (length tricks) > 0 then
      concatStringsSep " " tricks
    else
      "-V";

  silent = lib.optionalString (!verbose) ">/dev/null 2>&1";

  script = writeShellScriptBin pname ''
    export WINEARCH="win32"
    export WINEPREFIX="${location}"

    PATH=$PATH:${wine}/bin:${winetricks}/bin:${winestreamproxy}/bin
    HOME="$(echo ~)"
    USER="$(whoami)"
    OSU="$WINEPREFIX/drive_c/osu/osu!.exe"

    if [ ! -d "$WINEPREFIX" ]; then
      # install tricks
      winetricks -q -f ${tricksFmt}
      wineserver -k

      # install osu
      wine ${osusrc}
      wineserver -k
      mv "$WINEPREFIX/drive_c/users/$USER/Local Settings/Application Data/osu!" $WINEPREFIX/drive_c/osu
    fi

    winestreamproxy -f &
    wine ${wineFlags} "$OSU" "$@" ${silent}
    wineserver -w
  '';

  desktopItems = makeDesktopItem {
    name = pname;
    desktopName = "osu!stable";
    genericName = "osu!stable";
    exec = "${script}/bin/${pname}";
    categories = "Game;";
    icon = osuicon;
  };

in
symlinkJoin {
  name = pname;
  paths = [ desktopItems script ];

  meta = {
    description = "osu!stable installer and runner";
    homepage = "https://osu.ppy.sh";
    license.free = false;
    maintainer = lib.maintainers.fufexan;
    platforms = with lib.platforms; [ "i686-linux" "x86_64-linux" ];
  };
}
