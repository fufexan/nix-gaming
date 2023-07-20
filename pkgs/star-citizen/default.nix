{
  lib,
  makeDesktopItem,
  symlinkJoin,
  writeShellScriptBin,
  gamemode,
  winetricks,
  wine,
  dxvk,
  wineFlags ? "",
  pname ? "star-citizen",
  location ? "$HOME/Games/star-citizen",
  tricks ? ["arial" "vcrun2019" "win10"],
  preCommands ? "",
  postCommands ? "",
}: let
  version = "1.6.6";
  src = builtins.fetchurl rec {
    url = "https://install.robertsspaceindustries.com/star-citizen/RSI-Setup-${version}.exe";
    name = "RSI-Setup-${sha256}.exe";
    sha256 = "1lkv4nn4qmm9x5lgggvmcl2wvg94qk3r3sc2r7jzgwfchv3sfg42";
  };

  # concat winetricks args
  tricksFmt = with builtins;
    if (length tricks) > 0
    then concatStringsSep " " tricks
    else "-V";

  script = writeShellScriptBin pname ''
    export WINEARCH="win64"
    export DXVK_HUD=fps,compiler
    export WINEFSYNC=1
    export WINEESYNC=1
    export WINEPREFIX="${location}"

    PATH=$PATH:${wine}/bin:${winetricks}/bin
    USER="$(whoami)"
    RSI_LAUNCHER="$WINEPREFIX/drive_c/Program Files/Roberts Space Industries/RSI Launcher/RSI Launcher.exe"

    if [ ! -d "$WINEPREFIX" ]; then
      # install tricks
      winetricks -q -f ${tricksFmt}
      wineserver -k

      mkdir -p "$WINEPREFIX/drive_c/Program Files/Roberts Space Industries/StarCitizen/"{LIVE,PTU}


      # install launcher
      # Use silent install
      wine ${src} /S

      wineserver -k
    fi

    # EAC Fix
    if [ -d "$WINEPREFIX/drive_c/users/$USER/AppData/Roaming/EasyAntiCheat" ]
    then
      rm -rf "$WINEPREFIX/drive_c/users/$USER/AppData/Roaming/EasyAntiCheat";
    fi
    cd $WINEPREFIX

    ${dxvk}/bin/setup_dxvk.sh install --symlink

    ${preCommands}

    ${gamemode}/bin/gamemoderun wine ${wineFlags} "$RSI_LAUNCHER" "$@"
    wineserver -w

    ${postCommands}
  '';

  desktopItems = makeDesktopItem {
    name = pname;
    exec = "${script}/bin/${pname} %U";
    icon = "RSI";
    comment = "Star Citizen - Alpha";
    desktopName = "Star Ctizien";
    categories = ["Game"];
    mimeTypes = ["application/x-star-citizen-launcher"];
  };
in
  symlinkJoin {
    name = pname;
    paths = [
      desktopItems
      script
    ];

    meta = {
      description = "Star Citizen installer and launcher";
      homepage = "https://robertsspaceindustries.com/";
      license = lib.licenses.unfree;
      maintainers = with lib.maintainers; [fuzen];
      platforms = ["x86_64-linux"];
    };
  }
