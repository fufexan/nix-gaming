{
  lib,
  dxvk-w64,
  dxvk-w32,
  vkd3d-proton-w64,
  vkd3d-proton-w32,
  dxvk-nvapi-w32,
  dxvk-nvapi-w64,
  writeShellScriptBin,
  withDdraw ? false,
  cnc-ddraw,
  withCncDdraw ? withDdraw && !withD7vk,
  d7vk-w32,
  withD7vk ? false,
}:
# This installer is completely custom rather than using upstream scripts.
# dxvk is getting rid of their install script and vkd3d-proton's failed when ran more than once
# Since we need a custom one for dxvk it was easiest to just do both in one script
assert lib.assertMsg (!lib.and withCncDdraw withD7vk) "Cannot use both cnc-ddraw and d7vk at the same time";
  writeShellScriptBin "wineprefix-preparer"
  ''
    if ! command -v winepath; then
      >&2 echo "$(basename "$0"): No winepath binary in path. Run with wine available"
      exit 1
    fi
    export WINEPREFIX="''${WINEPREFIX:-$HOME/.wine}"
    echo "Preparing prefix $WINEPREFIX for gaming"

    set -xeuo pipefail

    echo "Killing running wine processes/wineserver"
    wineserver -k || true

    echo "Running wineboot -u to update prefix"
    WINEDEBUG=-all wineboot -u || :; sleep 1

    echo "Stopping processes in session"
    wineserver -k || true

    echo "Finding paths"
    win64_sys_path=$(WINEARCH=win64 wine winepath -u 'C:\windows\system32' 2> /dev/null)
    win64_sys_path="''${win64_sys_path/$'\r'/}"
    win32_sys_path=$(wine winepath -u 'C:\windows\syswow64' 2> /dev/null)
    win32_sys_path="''${win32_sys_path/$'\r'/}"

    echo "Found 32 bit path $win32_sys_path and 64 bit path $win64_sys_path"

    echo "Removing existing dxvk and vkd3d-proton DLLs"
    rm -rf {"$win32_sys_path","$win64_sys_path"}/{dxgi,d3d9,d3d10core,d3d11,d3d12,d3d12core}.dll

    echo "Installing dxvk DLLs"
    install -v -D -m644 -t "$win64_sys_path" ${dxvk-w64}/bin/*.dll
    install -v -D -m644 -t "$win32_sys_path" ${dxvk-w32}/bin/*.dll

    echo "Installing vkd3d-proton DLLs"
    install -v -D -m644 -t "$win64_sys_path" ${vkd3d-proton-w64}/bin/*.dll
    install -v -D -m644 -t "$win32_sys_path" ${vkd3d-proton-w32}/bin/*.dll

    echo "Installing dxvk-nvapi DLLs"
    install -v -D -m644 -t "$win64_sys_path" ${dxvk-nvapi-w32}/bin/*.dll
    install -v -D -m644 -t "$win32_sys_path" ${dxvk-nvapi-w32}/bin/*.dll
    install -v -D -m644 -t "$win64_sys_path" ${dxvk-nvapi-w64}/bin/*.dll
    install -v -D -m644 -t "$win32_sys_path" ${dxvk-nvapi-w64}/bin/*.dll

    echo "Adding native DllOverrides"
    for dll in dxgi d3d9 d3d10core d3d11 d3d12 d3d12core; do
      wine reg add 'HKEY_CURRENT_USER\Software\Wine\DllOverrides' /v $dll /d native /f >/dev/null 2>&1
    done

    ${lib.optionalString (withCncDdraw || withD7vk) ''
      echo "Removing existing DDraw"
      rm -f "$win32_sys_path/ddraw.dll" || true
      rm -f "$win32_sys_path/cnc-ddraw config.exe" || true
      rm -rf "$win32_sys_path/Shaders" || true

      echo "Installing DDraw"
      ${lib.optionalString withCncDdraw ''
        echo "Using cnc-ddraw"
        for item in "${cnc-ddraw}"/*; do
          base=$(basename "$item")
          if [[ "$base" != "ddraw.ini" ]]; then
            cp -r --no-preserve=all "$item" "$win32_sys_path"
          fi
        done
      ''}
      ${lib.optionalString withD7vk ''
        echo "Using d7vk"
        cp -r --no-preserve=all "${d7vk-w32}/bin/ddraw.dll" "$win32_sys_path/ddraw.dll"
      ''}
      echo "Adding native DDraw Override"
      wine reg add 'HKEY_CURRENT_USER\Software\Wine\DllOverrides' /v ddraw /d native /f >/dev/null 2>&1
    ''}
  ''
