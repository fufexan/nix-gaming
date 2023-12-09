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
  pkgs,
}: let
  version = "1.6.9";
  src = pkgs.fetchurl rec {
    url = "https://install.robertsspaceindustries.com/star-citizen/RSI-Setup-${version}.exe";
    name = "RSI-Setup-${version}.exe";
    hash = "sha256-h/JBhtYRV4XbPYPq+A8UcELmr/1inVWiV+A5/bCLLWM=";
  };

  # concat winetricks args
  tricksFmt = with builtins;
    if (length tricks) > 0
    then concatStringsSep " " tricks
    else "-V";

  script = writeShellScriptBin pname ''
    export WINEARCH="win64"
    export WINEFSYNC=1
    export WINEESYNC=1
    export WINEPREFIX="${location}"
    export WINEDLLOVERRIDES="libglesv2=b,nvapi,nvapi64=,powershell.exe="
    # Anti-cheat
    export SteamGameId="starcitizen"
    __GL_SHADER_DISK_CACHE=1
    __GL_SHADER_DISK_CACHE_SIZE=1073741824
    __GL_THREADED_OPTIMIZATIONS=1
    PATH=${lib.makeBinPath [wine winetricks]}:$PATH
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

  icon = pkgs.fetchurl {
    # Source: https://lutris.net/games/icon/star-citizen.png
    url = "https://github-production-user-asset-6210df.s3.amazonaws.com/17859309/255031314-2fac3a8d-a927-4aa9-a9ad-1c3e14466c20.png";
    hash = "sha256-19A1DyLQQcXQvVi8vW/ml+epF3WRlU5jTmI4nBaARF0=";
  };

  desktopItems = makeDesktopItem {
    name = pname;
    exec = "${script}/bin/${pname} %U";
    inherit icon;
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
