{ writeShellScriptBin
, winetricks
, wine ? null
, wineFlags ? ""
, name ? "osu!"
, location ? "$HOME/.osu"
, tricks ? [ "gdiplus" "dotnet40" "meiryo" ]
, dib
}:

let
  osusrc = builtins.fetchurl {
    url = "https://m1.ppy.sh/r/osu!install.exe";
    name = "osuinstall.exe";
    sha256 = "sha256-Cr8/FRoPv+q9uL+fBJFeaM0oQ1ROzHJxPM661gT+MKM=";
  };

  # discord ipc bridge stuff
  REGKEY = "HKEY_LOCAL_MACHINE\\Software\\Microsoft\\Windows\\CurrentVersion\\RunServices";
  wdib = "winediscordipcbridge.exe";
  dibInstall = ''
    cp ${dib}/bin/${wdib} $WINEPREFIX/drive_c/windows/${wdib}
    wine reg add '${REGKEY}' /v winediscordipcbridge /d 'C:\windows\${wdib}' /f
  '';

  # concat winetricks args
  tricksStmt = with builtins;
    if (length tricks) > 0 then
      concatStringsSep " " tricks
    else
      "-V";

  script = writeShellScriptBin name ''
    export WINEARCH="win32"
    export WINEPREFIX="${location}"

    PATH=$PATH:${wine}/bin:${winetricks}/bin
    HOME="$(echo ~)"
    USER="$(whoami)"
    OSU="$WINEPREFIX/drive_c/osu/osu!.exe"

    if [ ! -d "$WINEPREFIX" ]; then
      # install tricks
      winetricks -q -f ${tricksStmt}
      wineserver -k

      # install ipcbridge
      ${dibInstall}

      # install osu
      wine ${osusrc}
      wineserver -k
      mv "$WINEPREFIX/drive_c/users/$USER/Local Settings/Application Data/osu!" $WINEPREFIX/drive_c/osu
    fi

    wine net start ${wdib}
    wine ${wineFlags} "$OSU" "$@"
    wineserver -w
  '';
in
script
