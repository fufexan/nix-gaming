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
  pname ? "roblox-player",
  location ? "$HOME/Games/roblox-player",
  tricks ? [],
  preCommands ? "",
  postCommands ? "",
}: let
  version = "fc5e24b515354061";

  src = builtins.fetchurl rec {
    url = "https://setup.rbxcdn.com/version-${version}-Roblox.exe";
    name = "robloxinstall-${sha256}.exe";
    sha256 = "1gjgrznv44hi9pk2acagzbd2agw31l3h7jn95pzxrgjnryribqv8";
  };
  icon = builtins.fetchurl {
    url = "https://static.wikia.nocookie.net/logopedia/images/1/1e/Roblox_2022_%28Icon%29.png/revision/latest/scale-to-width-down/200?cb=20220831193228";
    name = "roblox-player-${sha}.png";
    sha256 = "0gjkzcs05l45034q7g6r7s1983pkx83wgynqdabgdvh03jh1wx0j";
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
    ROBLOX="$WINEPREFIX/drive_c/users/$USER/AppData/Local/Roblox/Versions/version-${version}/RobloxPlayerBeta.exe"

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
      platforms = with lib.platforms; ["x86_64-linux"];
    };
  }
