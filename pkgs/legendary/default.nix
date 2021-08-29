{ lib
, legendary-gl
, makeDesktopItem
, symlinkJoin
, writeShellScriptBin
, winestreamproxy
}:

{ wine
, winetricks
, wineFlags ? ""
, tricks ? [ ]

, pname ? ""
, codename ? ""
, nicename ? ""
, meta ? { }
, icon ? null
, location ? "$HOME/Games/${pname}"
}:

let
  # concat winetricks args
  tricksString = with builtins;
    if (length tricks) > 0 then
      concatStringsSep " " tricks
    else
      "-V";

  script = writeShellScriptBin pname ''
    export WINEPREFIX="${location}"
    export DXVK_HUD=compiler
    export WINEESYNC=1
    export WINEFSYNC=1
    export vblank_mode=0

    PATH=${wine}/bin:${winetricks}/bin:${legendary-gl}/bin:${winestreamproxy}:$PATH

    if [ ! -d "$WINEPREFIX" ]; then
      # install tricks
      winetricks -q ${tricksString}
      wineserver -k
    fi

    winestreamproxy -f &
    legendary update ${codename} --base-path ${location}
    legendary launch ${codename} --base-path ${location}
    wineserver -w
  '';

  desktopItems = makeDesktopItem {
    name = pname;
    exec = "${script}/bin/${pname}";
    inherit icon;
    desktopName = nicename;
    categories = "Game;";
  };
in
symlinkJoin {
  name = pname;
  paths = [ desktopItems script ];

  inherit meta;
}
