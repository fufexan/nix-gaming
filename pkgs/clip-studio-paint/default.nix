{
  lib,
  fetchurl,
  makeDesktopItem,
  symlinkJoin,
  writeShellScriptBin,
  gamemode,
  winetricks,
  wine,
  wineFlags ? "",
  pname ? "CLIPStudioPaint",
  location ? "$HOME/Games/${pname}",
  tricks ? ["cjkfonts" "gecko" "win81"],
  preCommands ? "",
  postCommands ? "",
}: let
  version = "1132";

  src = fetchurl {
    url = "https://vd.clipstudio.net/clipcontent/paint/app/${version}/CSP_${version}w_setup.exe";
    hash = "sha256-cFJcShjYMxwUKo7OJVRxQE3R/nrKa8cuqZWjA9Gmq/g=";
  };

  # concat winetricks args
  tricksFmt = with builtins;
    if (length tricks) > 0
    then concatStringsSep " " tricks
    else "-V";

  script = writeShellScriptBin pname ''
    export WINEARCH=win64
    export WINEPREFIX="${location}"

    PATH=$PATH:${wine}/bin:${winetricks}/bin
    CSP="$WINEPREFIX/drive_c/Program Files/CELSYS/CLIP STUDIO 1.5/CLIP STUDIO PAINT/CLIPStudioPaint.exe"

    if [ ! -d "$WINEPREFIX" ]; then
      winetricks -q ${tricksFmt}
      wineserver -k
    fi

    if [ ! -f "$CSP" ]; then
      echo "The last step will take quite a while (several minutes). Be patient."
      wine ${src}
      wineserver -k
    fi

    ${preCommands}

    wine ${wineFlags} "$CSP" "$@"
    wineserver -w

    ${postCommands}
  '';

  desktopItems = makeDesktopItem {
    name = pname;
    exec = "${script}/bin/${pname}";
    comment = "Clip Studio Paint";
    desktopName = "Clip Studio Paint";
    categories = ["Graphics"];
  };
in
  symlinkJoin {
    name = pname;
    paths = [
      desktopItems
      script
    ];
    meta = {
      description = "Digital painting program for creating manga and illustrations";
      homepage = "https://www.clipstudio.net";
      license = lib.licenses.unfree;
      platforms = ["x86_64-linux"];
    };
  }
