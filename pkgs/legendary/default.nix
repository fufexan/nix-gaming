{
  lib,
  makeDesktopItem,
  symlinkJoin,
  writeShellScriptBin,
  gamemode,
  legendary-gl,
  wine,
  winetricks,
  wine-discord-ipc-bridge,
  desktopName ? "",
  icon ? null,
  location ? "$HOME/Games",
  meta ? {},
  pname ? "",
  tricks ? [],
  preCommands ? "",
  postCommands ? "",
  discordIntegration ? true,
  gamemodeIntegration ? true,
}: let
  # concat winetricks args
  tricksString = with builtins;
    if (length tricks) > 0
    then concatStringsSep " " tricks
    else "-V";

  script = writeShellScriptBin pname ''
    export DXVK_HUD=compiler
    export WINEESYNC=1
    export WINEFSYNC=1
    export WINEPREFIX="${location}/${desktopName}"

    PATH=${wine}/bin:${winetricks}/bin:${legendary-gl}/bin:$PATH

    if [ ! -d "$WINEPREFIX" ]; then
      # install tricks
      winetricks -q ${tricksString}
      wineserver -k
    fi

    ${preCommands}

    legendary update "${desktopName}" --base-path "${location}/${desktopName}"
    ${lib.optionalString discordIntegration "wine ${wine-discord-ipc-bridge}/bin/winediscordipcbridge.exe &"}
    ${lib.optionalString gamemodeIntegration "${gamemode}/bin/gamemoderun"} legendary launch "${desktopName}" --base-path "${location}/${desktopName}"
    wineserver -w

    ${postCommands}
  '';

  desktopItems = makeDesktopItem {
    exec = "${script}/bin/${pname}";
    inherit icon desktopName;
    name = pname;
    categories = ["Game"];
  };
in
  symlinkJoin {
    name = pname;
    paths = [desktopItems script];

    inherit meta;
  }
