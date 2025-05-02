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
  dxvk-nvapi-w32,
  dxvk-nvapi-w64,
  umu-launcher,
  proton-ge-bin,
  wineFlags ? "",
  pname ? "star-citizen",
  location ? "$HOME/Games/star-citizen",
  tricks ? ["powershell" "corefonts" "tahoma"],
  useUmu ? false,
  protonPath ? "${proton-ge-bin.steamcompattool}/",
  protonVerbs ? ["waitforexitandrun"],
  wineDllOverrides ? ["winemenubuilder.exe=d" "nvapi=n" "nvapi64=n"],
  gameScopeEnable ? false,
  gameScopeArgs ? [],
  preCommands ? "",
  postCommands ? "",
  enableGlCache ? true,
  glCacheSize ? 10737418240, # 10GB
  disableEac ? true,
  pkgs,
}: let
  inherit (lib.strings) concatStringsSep optionalString toShellVars;
  # Latest version can be found: https://install.robertsspaceindustries.com/rel/2/latest.yml
  version = "2.3.1";
  src = pkgs.fetchurl {
    url = "https://install.robertsspaceindustries.com/rel/2/RSI%20Launcher-Setup-${version}.exe";
    name = "RSI Launcher-Setup-${version}.exe";
    hash = "sha256-w6o2UQsKlkK4E9luN+PO1mcbsI5nUHG7YEr1ZgcIAZo=";
  };

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
        export WINEDLLOVERRIDES="${lib.strings.concatStringsSep ";" wineDllOverrides}"
        export WINEDEBUG=-all

      ''
    }
    # ID for umu, not used for now
    export GAMEID="umu-starcitizen"
    export STORE="none"

    ${optionalString enableGlCache ''
      # NVIDIA
      export __GL_SHADER_DISK_CACHE=1;
      export __GL_SHADER_DISK_CACHE_SIZE=${builtins.toString glCacheSize};
      export __GL_SHADER_DISK_CACHE_PATH="$WINEPREFIX";
      export __GL_SHADER_DISK_CACHE_SKIP_CLEANUP=1;
      # MESA (Intel & AMD)
      export MESA_SHADER_CACHE_DIR="$WINEPREFIX";
      export MESA_SHADER_CACHE_MAX_SIZE="${builtins.toString (builtins.floor (glCacheSize / 1024 / 1024 / 1024))}G";

      export DXVK_ENABLE_NVAPI=1
    ''}


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
        # Ensure all tricks are installed
        ${toShellVars {
          inherit tricks;
          tricksInstalled = 1;
        }}

        # Copy dxvk-nvapi dlls to prefix
        install -v -D -m644 -t "$WINEPREFIX/drive_c/windows/syswow64" ${dxvk-nvapi-w32}/bin/*.dll
        install -v -D -m644 -t "$WINEPREFIX/drive_c/windows/system32" ${dxvk-nvapi-w32}/bin/*.dll
        install -v -D -m644 -t "$WINEPREFIX/drive_c/windows/syswow64" ${dxvk-nvapi-w64}/bin/*.dll
        install -v -D -m644 -t "$WINEPREFIX/drive_c/windows/system32" ${dxvk-nvapi-w64}/bin/*.dll


        for trick in "${"\${tricks[@]}"}"; do
           if ! winetricks list-installed | grep -qw "$trick"; then
             echo "winetricks: Installing $trick"
             winetricks -q -f "$trick"
             tricksInstalled=0
           fi
        done
        if [ "$tricksInstalled" -eq 0 ]; then
          # Ensure wineserver is restarted after tricks are installed
          wineserver -k
        fi

        if [ ! -e "$RSI_LAUNCHER" ]; then
          mkdir -p "$WINEPREFIX/drive_c/Program Files/Roberts Space Industries/StarCitizen/"{LIVE,PTU}

          # install launcher using silent install
          WINEDLLOVERRIDES="dxwebsetup.exe,dotNetFx45_Full_setup.exe,winemenubuilder.exe=d" wine ${src} /S

          wineserver -k
        fi
        ${dxvk}/bin/setup_dxvk.sh install --symlink
      ''
    }
    ${lib.optionalString disableEac ''
      # Anti-cheat
      export EOS_USE_ANTICHEATCLIENTNULL=1
    ''}
    cd "$WINEPREFIX"

    if [ "${"\${1:-}"}"  = "--shell" ]; then
      echo "Entered Shell for star-citizen"
      exec ${lib.getExe pkgs.bash};
    fi

    if [ -z "$DISPLAY" ]; then
      set -- "$@" "--in-process-gpu"
    fi

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
