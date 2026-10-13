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
  umuProtonPath ? "GE-Proton",
}:
let
  icon = fetchurl {
    # original url = "https://www.pngkey.com/png/full/16-160666_rocket-league-png.png";
    url = "https://user-images.githubusercontent.com/36706276/203341314-eaaa0659-9b79-4f40-8b4a-9bc1f2b17e45.png";
    name = "rocket-league.png";
    sha256 = "0a9ayr3vwsmljy7dpf8wgichsbj4i4wrmd8awv2hffab82fz4ykb";
  };

  bakkesmodIcon = fetchurl {
    url = "https://bp-prod.nyc3.digitaloceanspaces.com/site-assets/static/bm-transparent.png";
    name = "bakkesmod.png";
    sha256 = "18n6hcab25n9i4v2vmq6p8v7ii17p4x9i9jx3b300lfqm56239y7";
  };

  bakkesmod = callPackage ./bakkesmod.nix {
    inherit
      pname
      location
      umu-launcher-git
      ;
  };

  # Builds a launcher command. With `useBakkesmod`, launches through the
  # BakkesMod wrapper (which injects the mod) and always disables EAC, since
  # BakkesMod requires it. The plain launcher respects `enableEAC` so it can be
  # used for online play.
  mkScript =
    {
      name,
      useBakkesmod,
    }:
    writeShellScriptBin name ''
      export DXVK_HUD=${dxvk_hud}
      export WINEPREFIX="${location}"
      export GAMEID=umu-252950
      export STORE=egs
      export PROTONPATH=${umuProtonPath}
      ${lib.optionalString useBakkesmod "export PROTON_VERB=run"}

      PATH=${umu-launcher-git}/bin:${legendary-gl}/bin:${gamemode}/bin:$PATH

      legendary update Sugar --base-path "$WINEPREFIX"
      legendary launch Sugar --no-wine --wrapper "gamemoderun ${
        if useBakkesmod then "${bakkesmod}/bin/bakkesmod-wrapper" else "umu-run"
      }"${lib.optionalString (useBakkesmod || !enableEAC) " -noeac"}
    '';

  # Plain, unmodified Rocket League (online-capable when enableEAC is set).
  script = mkScript {
    name = pname;
    useBakkesmod = false;
  };

  desktopItems = makeDesktopItem {
    name = pname;
    exec = "${script}/bin/${pname}";
    inherit icon;
    desktopName = "Rocket League";
    categories = [ "Game" ];
  };

  # Separate BakkesMod command, so a single install offers both unmodified
  # online RL and modded offline RL.
  bakkesmodScript = mkScript {
    name = "bakkesmod";
    useBakkesmod = true;
  };

  bakkesmodDesktopItem = makeDesktopItem {
    name = "bakkesmod";
    exec = "${bakkesmodScript}/bin/bakkesmod";
    icon = bakkesmodIcon;
    desktopName = "Bakkesmod (Rocket League mod)";
    categories = [ "Game" ];
  };
in
symlinkJoin {
  name = pname;
  paths = [
    desktopItems
    script
  ]
  ++ lib.optionals enableBakkesmod [
    bakkesmodScript
    bakkesmodDesktopItem
    bakkesmod
  ];

  meta = {
    description = "Rocket League installer and runner (using legendary)";
    homepage = "https://rocketleague.com";
    license = lib.licenses.unfree;
    maintainers = with lib.maintainers; [ fufexan ];
    platforms = [ "x86_64-linux" ];
  };
}
