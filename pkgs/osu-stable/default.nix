{
  lib,
  fetchurl,
  makeDesktopItem,
  symlinkJoin,
  writeShellScriptBin,
  gamemode,
  wine-discord-ipc-bridge,
  winetricks,
  wine,
  umu-launcher,
  proton-osu-bin,
  wineFlags ? "",
  pname ? "osu-stable",
  location ? "$HOME/.osu",
  useUmu ? true,
  useGameMode ? true,
  protonPath ? "${proton-osu-bin.steamcompattool}",
  protonVerbs ? ["waitforexitandrun"],
  tricks ? ["gdiplus" "dotnet45" "meiryo"],
  preCommands ? "",
  postCommands ? "",
  osu-mime,
}: let
  src = fetchurl rec {
    url = "https://m1.ppy.sh/r/osu!install.exe";
    name = "osuinstall-${lib.strings.sanitizeDerivationName sha256}.exe";
    sha256 = (builtins.fromJSON (builtins.readFile ./info.json)).hash;
  };

  # concat winetricks args
  tricksFmt = with builtins;
    if (length tricks) > 0
    then concatStringsSep " " tricks
    else "-V";

  gameMode = lib.strings.optionalString useGameMode "${gamemode}/bin/gamemoderun";

  script = writeShellScriptBin pname ''
    export WINEARCH="win32"
    export WINEPREFIX="${location}"
    # sets realtime priority for wine
    export STAGING_RT_PRIORITY_SERVER=1
    # disables vsync for OpenGL
    export vblank_mode=0

    # ID for umu
    export GAMEID="osu-wine-umu"
    export STORE="none"

    PATH=${
      lib.makeBinPath (
        if useUmu
        then [umu-launcher]
        else [wine winetricks]
      )
    }:$PATH
    USER="$(whoami)"
    OSU="$WINEPREFIX/drive_c/osu/osu!.exe"

    ${
      if useUmu
      then ''
        export PROTON_VERBS="${lib.strings.concatStringsSep "," protonVerbs}"
        export PROTONPATH="${protonPath}"

        if [ ! -d "$WINEPREFIX" ]; then
          umu-run winetricks ${tricksFmt}
        fi

        if [ ! -f "$OSU" ]; then
          umu-run ${src}
          mv "$WINEPREFIX/drive_c/users/steamuser/AppData/Local/osu!" $WINEPREFIX/drive_c/osu
        fi
      ''
      else ''
        if [ ! -d "$WINEPREFIX" ]; then
          # install tricks
          winetricks -q -f ${tricksFmt}
          wineserver -k

          # install osu
          wine ${src}
          wineserver -k
          mv "$WINEPREFIX/drive_c/users/$USER/AppData/Local/osu!" $WINEPREFIX/drive_c/osu
        fi
      ''
    }

    ${preCommands}

    ${
      if useUmu
      then ''
        ${gameMode} umu-run "$OSU" "$@"
      ''
      else ''
        wine ${wine-discord-ipc-bridge}/bin/winediscordipcbridge.exe &
        ${gameMode} wine ${wineFlags} "$OSU" "$@"
        wineserver -w
      ''
    }

    ${postCommands}
  '';

  desktopItems = makeDesktopItem {
    name = pname;
    exec = "${script}/bin/${pname} %U";
    icon = "osu!"; # icon comes from the osu-mime package
    comment = "Rhythm is just a *click* away";
    desktopName = "osu!stable";
    categories = ["Game"];
    mimeTypes = [
      "application/x-osu-skin-archive"
      "application/x-osu-replay"
      "application/x-osu-beatmap-archive"
      "x-scheme-handler/osu"
    ];
  };
in
  symlinkJoin {
    name = pname;
    paths = [
      desktopItems
      script
      osu-mime
    ];

    meta = {
      description = "osu!stable installer and runner";
      homepage = "https://osu.ppy.sh";
      license = lib.licenses.unfree;
      maintainers = with lib.maintainers; [fufexan];
      passthru.updateScript = ./update.sh;
      platforms = ["x86_64-linux"];
    };
  }
