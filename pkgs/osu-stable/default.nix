{
  lib,
  makeDesktopItem,
  symlinkJoin,
  writeShellScriptBin,
  gamemode,
  wine-discord-ipc-bridge,
  winetricks,
  wine,
  wineFlags ? "",
  pname ? "osu-stable",
  location ? "$HOME/.osu",
  tricks ? ["gdiplus" "dotnet40" "meiryo"],
  preCommands ? "",
  postCommands ? "",
}: let
  src = builtins.fetchurl rec {
    url = "https://m1.ppy.sh/r/osu!install.exe";
    name = "osuinstall-${sha256}.exe";
    sha256 = "1pfj2jnf9vxmbw48v5kv060h66awn8sr67cfzp534lrc2qi54kkg";
  };
  icon = builtins.fetchurl {
    # original url = "https://i.ppy.sh/013ed2c11b34720790e74035d9f49078d5e9aa64/68747470733a2f2f6f73752e7070792e73682f77696b692f696d616765732f4272616e645f6964656e746974795f67756964656c696e65732f696d672f75736167652d66756c6c2d636f6c6f75722e706e67";
    url = "https://user-images.githubusercontent.com/36706276/203341604-085a1896-539e-4401-a458-ad6ee4209df8.png";
    name = "osu.png";
    sha256 = "00qka8pn5d5jrlsadwn30aywqn60xqb1nsx2qiqsd73i4xbha0rn";
  };

  # concat winetricks args
  tricksFmt = with builtins;
    if (length tricks) > 0
    then concatStringsSep " " tricks
    else "-V";

  script = writeShellScriptBin pname ''
    export WINEARCH="win32"
    export WINEPREFIX="${location}"
    # sets realtime priority for wine
    export STAGING_RT_PRIORITY_SERVER=1
    # disables vsync for OpenGL
    export vblank_mode=0

    PATH=$PATH:${wine}/bin:${winetricks}/bin
    USER="$(whoami)"
    OSU="$WINEPREFIX/drive_c/osu/osu!.exe"

    if [ ! -d "$WINEPREFIX" ]; then
      # install tricks
      winetricks -q -f ${tricksFmt}
      wineserver -k

      # install osu
      wine ${src}
      wineserver -k
      mv "$WINEPREFIX/drive_c/users/$USER/AppData/Local/osu!" $WINEPREFIX/drive_c/osu
    fi

    ${preCommands}

    wine ${wine-discord-ipc-bridge}/bin/winediscordipcbridge.exe &
    ${gamemode}/bin/gamemoderun wine ${wineFlags} "$OSU" "$@"
    wineserver -w

    ${postCommands}
  '';

  desktopItems = makeDesktopItem {
    name = pname;
    exec = "${script}/bin/${pname}";
    inherit icon;
    comment = "Rhythm is just a *click* away";
    desktopName = "osu!stable";
    categories = ["Game"];
  };
in
  symlinkJoin {
    name = pname;
    paths = [desktopItems script];

    meta = {
      description = "osu!stable installer and runner";
      homepage = "https://osu.ppy.sh";
      license = lib.licenses.unfree;
      maintainers = with lib.maintainers; [fufexan];
      platforms = with lib.platforms; ["x86_64-linux"];
    };
  }
