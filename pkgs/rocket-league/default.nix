{
  lib,
  fetchurl,
  makeDesktopItem,
  symlinkJoin,
  writeShellScriptBin,
  gamemode,
  legendary-gl,
  winetricks,
  wine,
  pname ? "rocket-league",
  location ? (
    if useUmu
    then "$HOME/Games/umu/umu-252950"
    else "$HOME/Games/${pname}"
  ),
  tricks ? ["arial" "cjkfonts" "vcrun2019" "d3dcompiler_43" "d3dcompiler_47" "d3dx9"],
  dxvk_hud ? "compiler",
  callPackage,
  enableBakkesmod ? false,
  umu,
  useUmu ? false,
}: let
  icon = fetchurl {
    # original url = "https://www.pngkey.com/png/full/16-160666_rocket-league-png.png";
    url = "https://user-images.githubusercontent.com/36706276/203341314-eaaa0659-9b79-4f40-8b4a-9bc1f2b17e45.png";
    name = "rocket-league.png";
    sha256 = "0a9ayr3vwsmljy7dpf8wgichsbj4i4wrmd8awv2hffab82fz4ykb";
  };

  # concat winetricks args
  tricksString = with builtins;
    if (length tricks) > 0
    then concatStringsSep " " tricks
    else "-V";

  script = writeShellScriptBin pname ''

    export DXVK_HUD=${dxvk_hud}
    export WINEPREFIX="${location}"

    ${
      if useUmu
      then ''
        export GAMEID=umu-252950
        export STORE=egs

        PATH=${umu}/bin:${legendary-gl}/bin:${gamemode}/bin:$PATH

        legendary update Sugar --base-path ${location}
        legendary launch Sugar --no-wine --wrapper "gamemoderun umu-run" --base-path ${location}
      ''
      else ''
        export MESA_GL_VERSION_OVERRIDE=4.4COMPAT
        export WINEFSYNC=1
        export WINEESYNC=1
        export __GL_SHADER_DISK_CACHE=1
        export __GL_SHADER_DISK_CACHE_PATH="${location}"

        PATH=${wine}/bin:${winetricks}/bin:${legendary-gl}/bin:${gamemode}/bin:$PATH

        if [ ! -d "$WINEPREFIX" ]; then
          # install tricks
          winetricks -q ${tricksString}
          wineserver -k
        fi

        legendary update Sugar --base-path ${location}
        gamemoderun legendary launch Sugar --base-path ${location}
        wineserver -w
      ''
    }
  '';

  desktopItems = makeDesktopItem {
    name = pname;
    exec = "${script}/bin/${pname}";
    inherit icon;
    desktopName = "Rocket League";
    categories = ["Game"];
  };

  bakkesmod = callPackage ./bakkesmod.nix {inherit location wine umu useUmu;};
in
  symlinkJoin {
    name = pname;
    paths = [desktopItems script] ++ lib.optionals enableBakkesmod [bakkesmod];

    meta = {
      description = "Rocket League installer and runner (using legendary)";
      homepage = "https://rocketleague.com";
      license = lib.licenses.unfree;
      maintainers = with lib.maintainers; [fufexan];
      platforms = ["x86_64-linux"];
    };
  }
