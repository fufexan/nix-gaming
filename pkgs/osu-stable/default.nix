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
  umu-launcher-git,
  proton-osu-bin,
  flatpak-xdg-utils,
  wineFlags ? "",
  pname ? "osu-stable",
  location ? "$HOME/.osu",
  nativeFileManager ? "${flatpak-xdg-utils}/bin/xdg-open",
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

  # Based on: https://gist.github.com/maotovisk/1bf3a7c9054890f91b9234c3663c03a2
  openNativeFolder = writeShellScriptBin "wine-open-native-folder" ''
    windows_path="$1"
    windows_path="''${windows_path#\"}"
    windows_path="''${windows_path%\"}"
    windows_path="''${windows_path%\'}"

    normalized_path="$(printf '%s' "$windows_path" | tr '\\' '/')"

    case "$normalized_path" in
      [A-Za-z]:*)
        drive_letter="$(printf '%s' "$normalized_path" | cut -c1 | tr '[:upper:]' '[:lower:]')"
        path_part="''${normalized_path#?:}"
        path_part="''${path_part#/}"
        case "$drive_letter" in
          z)
            linux_path="/$path_part"
            ;;
          c)
            linux_path="$WINEPREFIX/drive_c/$path_part"
            ;;
          *)
            linux_path="$WINEPREFIX/dosdevices/$drive_letter:/$path_part"
            ;;
        esac
        ;;
      *)
        linux_path="$normalized_path"
        ;;
    esac

    exec "${nativeFileManager}" "$linux_path"
  '';

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
        then [umu-launcher-git]
        else [wine winetricks]
      )
    }:$PATH
    USER="$(whoami)"
    OSU="$WINEPREFIX/drive_c/osu/osu!.exe"

    configure_native_file_manager() {
      local runner="$1"
      local marker="$WINEPREFIX/.native-file-manager-configured"

      if [ -f "$marker" ]; then
        return
      fi

      "$runner" reg add 'HKEY_CLASSES_ROOT\folder\shell\open\command' /ve /d '"/bin/sh" "${openNativeFolder}/bin/wine-open-native-folder" "%1"' /f
      "$runner" reg delete 'HKEY_CLASSES_ROOT\folder\shell\open\ddeexec' /f || true

      touch "$marker"
    }

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

        configure_native_file_manager umu-run
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

        configure_native_file_manager wine
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
      openNativeFolder
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
