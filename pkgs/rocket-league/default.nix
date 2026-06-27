{
  lib,
  fetchurl,
  makeDesktopItem,
  symlinkJoin,
  writeShellScriptBin,
  gamemode,
  legendary-gl,
  umu-launcher-git,
  pname ? "rocket-league",
  location ? "$HOME/Games/umu/umu-252950",
  dxvk_hud ? "compiler",
  callPackage,
  enableEAC ? true,
  enableBakkesmod ? false,
}:
let
  icon = fetchurl {
    # original url = "https://www.pngkey.com/png/full/16-160666_rocket-league-png.png";
    url = "https://user-images.githubusercontent.com/36706276/203341314-eaaa0659-9b79-4f40-8b4a-9bc1f2b17e45.png";
    name = "rocket-league.png";
    sha256 = "0a9ayr3vwsmljy7dpf8wgichsbj4i4wrmd8awv2hffab82fz4ykb";
  };

  script = writeShellScriptBin pname ''
    export DXVK_HUD=${dxvk_hud}
    export WINEPREFIX="${location}"
    ${''
      export GAMEID=umu-252950
      export STORE=egs
      export PROTONPATH=GE-Proton
      ${lib.optionalString enableBakkesmod "export PROTON_VERB=runinprefix"}

      PATH=${umu-launcher-git}/bin:${legendary-gl}/bin:${gamemode}:$PATH

      legendary update Sugar --base-path "$WINEPREFIX"
      legendary launch Sugar --no-wine --wrapper "gamemoderun umu-run"${
        lib.optionalString (!enableEAC) " -noeac"
      }
    ''}
  '';

  desktopItems = makeDesktopItem {
    name = pname;
    exec = "${script}/bin/${pname}";
    inherit icon;
    desktopName = "Rocket League";
    categories = [ "Game" ];
  };

  bakkesmod = callPackage ./bakkesmod.nix {
    inherit
      location
      umu-launcher-git
      ;
  };
in
symlinkJoin {
  name = pname;
  paths = [
    desktopItems
    script
  ]
  ++ lib.optionals enableBakkesmod [ bakkesmod ];

  meta = {
    description = "Rocket League installer and runner (using legendary)";
    homepage = "https://rocketleague.com";
    license = lib.licenses.unfree;
    maintainers = with lib.maintainers; [ fufexan ];
    platforms = [ "x86_64-linux" ];
  };
}
