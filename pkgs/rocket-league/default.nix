{ lib
, makeDesktopItem
, symlinkJoin
, writeShellScriptBin

, legendary-gl
, winetricks

, wine
, wineFlags ? ""
, pname ? "rocket-league"
, location ? "$HOME/Games/${pname}"
, tricks ? [ "dxvk" "win10" ]
}:

let
  icon = builtins.fetchurl {
    url = "https://www.pngkey.com/png/full/16-160666_rocket-league-png.png";
    name = "rocket-league.png";
    sha256 = "09n90zvv8i8bk3b620b6qzhj37jsrhmxxf7wqlsgkifs4k2q8qpf";
  };

  # concat winetricks args
  tricksString = with builtins;
    if (length tricks) > 0 then
      concatStringsSep " " tricks
    else
      "-V";

  script = writeShellScriptBin pname ''
    export WINEPREFIX="${location}"
    export DXVK_HUD=compiler
    export WINEFSYNC=1
    export WINEESYNC=1

    PATH=${wine}/bin:${winetricks}/bin:${legendary-gl}/bin:$PATH

    if [ ! -d "$WINEPREFIX" ]; then
      # install tricks
      winetricks -q ${tricksString}
      wineserver -k
    fi

    legendary update Sugar --base-path ${location}
    legendary launch Sugar --base-path ${location}
    wineserver -w
  '';

  desktopItems = makeDesktopItem {
    name = pname;
    exec = "${script}/bin/${pname}";
    inherit icon;
    desktopName = "Rocket League";
    categories = "Game;";
  };
in
symlinkJoin {
  name = pname;
  paths = [ desktopItems script ];

  meta = {
    description = "Rocket League installer and runner (using legendary)";
    homepage = "https://rocketleague.com";
    maintainer = lib.maintainers.fufexan;
    platforms = with lib.platforms; [ "x86_64-linux" ];
  };
}
