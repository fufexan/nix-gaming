{
  lib,
  makeDesktopItem,
  symlinkJoin,
  writeShellScriptBin,
  gamemode,
  winetricks,
  wine,
  dxvk,
  umu,
  proton-ge-bin,
  wineFlags ? "",
  pname ? "star-citizen",
  location ? "$HOME/Games/star-citizen",
  tricks ? [],
  useUmu ? false,
  protonPath ? "${proton-ge-bin.steamcompattool}/",
  protonVerbs ? ["waitforexitandrun"],
  wineDllOverrides ? ["powershell.exe=n"],
  preCommands ? "",
  postCommands ? "",
  enableGlCache ? true,
  glCacheSize ? 1073741824,
  pkgs,
}: let
  inherit (lib.strings) concatStringsSep optionalString;
  version = "1.6.10";
  src = pkgs.fetchurl {
    url = "https://install.robertsspaceindustries.com/star-citizen/RSI-Setup-${version}.exe";
    name = "RSI-Setup-${version}.exe";
    hash = "sha256-axttJvw3MFmhLC4e+aqtf4qx0Z0x4vz78LElyGkMAbs=";
  };

  # Powershell stub for star-citizen
  powershell-stub = pkgs.callPackage ./powershell-stub.nix {};

  # concat winetricks args
  tricksFmt =
    if (builtins.length tricks) > 0
    then concatStringsSep " " tricks
    else "-V";

  script = writeShellScriptBin pname ''
    export WINEARCH="win64"
    export WINEPREFIX="${location}"
    ${optionalString
      #this option doesn't work on umu, an umu TOML config file will be needed instead
      (!useUmu) ''
        export WINEFSYNC=1
        export WINEESYNC=1
        export WINEDLLOVERRIDES="${lib.strings.concatStringsSep "," wineDllOverrides}"
      ''}
    # ID for umu, not used for now
    export GAMEID="umu-starcitizen"
    export STORE="none"
    # Anti-cheat
    export EOS_USE_ANTICHEATCLIENTNULL=1
    # Nvidia tweaks
    export WINE_HIDE_NVIDIA_GPU=1
    export __GL_SHADER_DISK_CACHE=${
      if enableGlCache
      then "1"
      else "0"
    }
    export __GL_SHADER_DISK_CACHE_SIZE=${toString glCacheSize}
    export WINE_HIDE_NVIDIA_GPU=1
    # AMD
    export dual_color_blend_by_location="true"

    PATH=${lib.makeBinPath (
      if useUmu
      then [umu]
      else [wine winetricks]
    )}:$PATH
    USER="$(whoami)"
    RSI_LAUNCHER="$WINEPREFIX/drive_c/Program Files/Roberts Space Industries/RSI Launcher/RSI Launcher.exe"
    ${
      if useUmu
      then ''
        export PROTON_VERBS="${concatStringsSep "," protonVerbs}"
        export PROTONPATH="${protonPath}"
        if [ ! -f "$RSI_LAUNCHER" ]; then umu "${src}" /S; fi
      ''
      else ''
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
        ${dxvk}/bin/setup_dxvk.sh install --symlink
      ''
    }
    # EAC Fix
    if [ -d "$WINEPREFIX/drive_c/users/$USER/AppData/Roaming/EasyAntiCheat" ]
    then
      rm -rf "$WINEPREFIX/drive_c/users/$USER/AppData/Roaming/EasyAntiCheat";
    fi
    cd $WINEPREFIX

    ${powershell-stub}/bin/install.sh

    ${preCommands}
    ${
      if useUmu
      then ''
        ${gamemode}/bin/gamemoderun umu "$RSI_LAUNCHER" "$@"
      ''
      else ''
        ${gamemode}/bin/gamemoderun wine ${wineFlags} "$RSI_LAUNCHER" "$@"
        wineserver -w
      ''
    }
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
    desktopName = "Star Citizen";
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
