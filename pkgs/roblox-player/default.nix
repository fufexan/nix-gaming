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
  wineFlags ? "",
  pname ? "roblox-player",
  location ? "$HOME/Games/roblox-player",
  tricks ? [],
  preCommands ? "",
  postCommands ? "",
}: let
  version = "37cf60402a5648b4";

  src = fetchurl rec {
    url = "https://setup.rbxcdn.com/version-${version}-Roblox.exe";
    name = "robloxinstall-${sha256}.exe";
    sha256 = "1jqsl0qcvkmdmw46zc0xkr9cvpxjhphwg7xwxgk4gcskgyzaqgrx";
  };
  icon = fetchurl {
    # original url = "https://static.wikia.nocookie.net/logopedia/images/1/1e/Roblox_2022_%28Icon%29.png/revision/latest/scale-to-width-down/200?cb=20220831193228";
    url = "https://user-images.githubusercontent.com/36706276/203341006-a75060b5-a718-4e30-a78c-ecc39d7ea5e7.png";
    name = "roblox-player.png";
    sha256 = "1mhi0s40nsqka2xmhl8bs4043dzs4n1ivkh6psdysh3ylhcdh44g";
  };

  # concat winetricks args
  tricksFmt = with builtins;
    if (length tricks) > 0
    then concatStringsSep " " tricks
    else "-V";

  script = writeShellScriptBin pname ''
    export WINEPREFIX="${location}"
    # disables vsync for OpenGL
    export vblank_mode=0

    PATH=$PATH:${wine}/bin:${winetricks}/bin
    USER="$(whoami)"
    ROBLOX="$WINEPREFIX/drive_c/Program Files (x86)/Roblox/Versions/version-${version}/RobloxPlayerBeta.exe"

    if [ ! -d "$WINEPREFIX" ]; then
      # install tricks
      winetricks -q -f ${tricksFmt}
      wineserver -k

      # install Roblox
      wine ${src}
      wineserver -k
    fi

    ${preCommands}

    wine ${wine-discord-ipc-bridge}/bin/winediscordipcbridge.exe &
    ${gamemode}/bin/gamemoderun wine ${wineFlags} "$ROBLOX" "$@"
    wineserver -w

    ${postCommands}
  '';

  desktopItems = makeDesktopItem {
    name = pname;
    exec = "${script}/bin/${pname}";
    inherit icon;
    comment = "Roblox Player";
    desktopName = "Roblox Player";
    categories = ["Game"];
    mimeTypes = ["x-scheme-handler/roblox-player"];
  };
in
  symlinkJoin {
    name = pname;
    paths = [desktopItems script];

    meta = {
      description = "Roblox Player installer and runner";
      homepage = "https://roblox.com";
      license = lib.licenses.unfree;
      maintainers = with lib.maintainers; [fufexan];
      platforms = ["x86_64-linux"];
    };
  }
