{
  lib,
  makeDesktopItem,
  symlinkJoin,
  writeShellScriptBin,
  gamemode,
  legendary-gl,
  winetricks,
  wine,
  wineFlags ? "",
  pname ? "rocket-league",
  location ? "$HOME/Games/${pname}",
  tricks ? ["dxvk" "win10"],
}: let
  icon = builtins.fetchurl {
    # original url = "https://www.pngkey.com/png/full/16-160666_rocket-league-png.png";
    url = "https://user-images.githubusercontent.com/36706276/203341314-eaaa0659-9b79-4f40-8b4a-9bc1f2b17e45.png";
    name = "rocket-league.png";
    sha256 = "0a9ayr3vwsmljy7dpf8wgichsbj4i4wrmd8awv2hffab82fz4ykb";
  };

  # concat winetricks args
  tricksString = with builtins;
    if (length tricks) > 0
    then concatStringsSep " " tricks
    else "-V";

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
    gamemoderun legendary launch Sugar --base-path ${location}
    wineserver -w
  '';

  desktopItems = makeDesktopItem {
    name = pname;
    exec = "${script}/bin/${pname}";
    inherit icon;
    desktopName = "Rocket League";
    categories = ["Game"];
  };
in
  symlinkJoin {
    name = pname;
    paths = [desktopItems script];

    meta = {
      description = "Rocket League installer and runner (using legendary)";
      homepage = "https://rocketleague.com";
      license = lib.licenses.unfree;
      maintainers = with lib.maintainers; [fufexan];
      platforms = ["x86_64-linux"];
    };
  }
