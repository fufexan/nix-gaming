{
  lib,
  makeDesktopItem,
  symlinkJoin,
  writeShellScriptBin,
  gamemode,
  gamescope,
  winetricks,
  wine,
  dxvk,
  umu-launcher,
  proton-ge-bin,
  wineFlags ? "",
  pname ? "star-citizen",
  location ? "$HOME/Games/star-citizen",
  tricks ? ["powershell" "corefonts" "tahoma"],
  useUmu ? false,
  protonPath ? "${proton-ge-bin.steamcompattool}/",
  protonVerbs ? ["waitforexitandrun"],
  wineDllOverrides ? ["winemenubuilder.exe=d"],
  gameScopeEnable ? false,
  gameScopeArgs ? [],
  preCommands ? "",
  postCommands ? "",
  enableGlCache ? true,
  glCacheSize ? 1073741824,
  disableEac ? true,
  pkgs,
}: let
  inherit (lib.strings) concatStringsSep optionalString;
  # Latest version can be found: https://install.robertsspaceindustries.com/rel/2/latest.yml
  version = "2.3.1";
  src = pkgs.fetchurl {
    url = "https://install.robertsspaceindustries.com/rel/2/RSI%20Launcher-Setup-${version}.exe";
    name = "RSI Launcher-Setup-${version}.exe";
    hash = "sha256-w6o2UQsKlkK4E9luN+PO1mcbsI5nUHG7YEr1ZgcIAZo=";
  };

  # Powershell stub for star-citizen

  # concat winetricks args
  tricksFmt =
    if (builtins.length tricks) > 0
    then concatStringsSep " " tricks
    else "-V";

  gameScope = lib.strings.optionalString gameScopeEnable "${gamescope}/bin/gamescope ${concatStringsSep " " gameScopeArgs} --";

  libs = with pkgs; [freetype vulkan-loader];

  script = writeShellScriptBin pname ''
    export WINETRICKS_LATEST_VERSION_CHECK=disabled
    export WINEARCH="win64"
    mkdir -p "${location}"
    export WINEPREFIX="$(readlink -f "${location}")"
    ${
      optionalString
      #this option doesn't work on umu, an umu TOML config file will be needed instead
      (!useUmu)
      ''
        export WINEFSYNC=1
        export WINEESYNC=1
        export WINEDLLOVERRIDES="${lib.strings.concatStringsSep "," wineDllOverrides}"
        ${lib.optionalString disableEac ''
          # Anti-cheat
          export EOS_USE_ANTICHEATCLIENTNULL=1
        ''}
        # Nvidia tweaks
        export WINE_HIDE_NVIDIA_GPU=1
        # AMD
        export dual_color_blend_by_location="true"
        export WINEDEBUG=-all

      ''
    }
    # ID for umu, not used for now
    export GAMEID="umu-starcitizen"
    export STORE="none"

    export __GL_SHADER_DISK_CACHE=${
      if enableGlCache
      then "1"
      else "0"
    }
    export __GL_SHADER_DISK_CACHE_SIZE=${toString glCacheSize}

    PATH=${
      lib.makeBinPath (
        if useUmu
        then [umu-launcher]
        else [wine winetricks]
      )
    }:$PATH
    export LD_LIBRARY_PATH=${lib.makeLibraryPath libs}:$LD_LIBRARY_PATH
    USER="$(whoami)"
    RSI_LAUNCHER="$WINEPREFIX/drive_c/Program Files/Roberts Space Industries/RSI Launcher/RSI Launcher.exe"
    ${
      if useUmu
      then ''
        export PROTON_VERBS="${concatStringsSep "," protonVerbs}"
        export PROTONPATH="${protonPath}"
        if [ ! -f "$RSI_LAUNCHER" ]; then umu-run "${src}" /S; fi
      ''
      else ''
        if [ ! -e "$RSI_LAUNCHER" ]; then
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
    ${lib.optionalString disableEac ''
      # EAC Fix
      if [ -d "$WINEPREFIX/drive_c/users/$USER/AppData/Roaming/EasyAntiCheat" ]
      then
        rm -rf "$WINEPREFIX/drive_c/users/$USER/AppData/Roaming/EasyAntiCheat";
      fi
    ''}
    cd "$WINEPREFIX"

    ${preCommands}
    ${
      if useUmu
      then ''
        ${gameScope} ${gamemode}/bin/gamemoderun umu-run "$RSI_LAUNCHER" "$@"
      ''
      else ''
        if [[ -t 1 ]]; then
            ${gameScope} ${gamemode}/bin/gamemoderun wine ${wineFlags} "$RSI_LAUNCHER" "$@"
        else
            export LOG_DIR=$(mktemp -d)
            echo "Working arround known launcher error by outputting logs to $LOG_DIR"
            ${gameScope} ${gamemode}/bin/gamemoderun wine ${wineFlags} "$RSI_LAUNCHER" "$@" >"$LOG_DIR/RSIout" 2>"$LOG_DIR/RSIerr"
        fi
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
