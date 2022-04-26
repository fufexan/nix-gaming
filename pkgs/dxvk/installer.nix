{ dxvk-x86
, dxvk-x64
, runCommandNoCC
, writeShellScriptBin
, pkgsCross
}:
let
  setupScript = runCommandNoCC "dxvk-setup" {}
    ''
    cp ${dxvk-x86.src}/setup_dxvk.sh $out
    '';
in
writeShellScriptBin "dxvk-installer"
''
  dxvk_lib32=/../../../../${dxvk-x86}/bin
  dxvk_lib64=/../../../../${dxvk-x64}/bin
  WINEPREFIX=''${WINEPREFIX:-"$HOME/.wine"}

  . ${setupScript}
  cp -v ${pkgsCross.mingwW64.windows.mcfgthreads}/bin/mcfgthread-12.dll "$WINEPREFIX/dosdevices/c:/windows/syswow64/"
  cp -v ${pkgsCross.mingw32.windows.mcfgthreads}/bin/mcfgthread-12.dll "$WINEPREFIX/dosdevices/c:/windows/system32/"
  dxvk_lib32=/../../../../${pkgsCross.mingw32.windows.mcfgthreads}/bin
  dxvk_lib64=/../../../../${pkgsCross.mingwW64.windows.mcfgthreads}/bin
  install mcfgthread-12
''
