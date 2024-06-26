{
  lib,
  requireFile,
  makeDesktopItem,
  copyDesktopItems,
  autoPatchelfHook,
  makeBinaryWrapper,
  stdenvNoCC,
  zip,
  unzip,
  # Runtime deps.
  SDL2,
  libcxx,
  libGL,
  fmodex,
  libmx,
  libX11,
  libXext,
  libxcb,
  libXau,
  libXdmcp,
}: let
  commonDeps = [
    SDL2
    libcxx
    libGL
    fmodex
    libmx
    fmodex
    libX11
    libXext
    libxcb
    libXau
    libXdmcp
  ];
in
  stdenvNoCC.mkDerivation rec {
    pname = "darkest-dungeon";
    version = "24839_28859";

    # The official installer must be provided by the end user.
    src = requireFile {
      name = "darkest_dungeon_${version}.sh";
      url = "https://www.gog.com/game/darkest_dungeon";
      sha256 = "2b235b43d8d6ab4b2a4b80b627ce2a9c31c1b4bee16fc6f9dda68c29cb5da99c";
    };

    nativeBuildInputs =
      [
        autoPatchelfHook
        makeBinaryWrapper
        unzip
        zip
        copyDesktopItems
      ]
      ++ commonDeps;

    desktopItems = [
      (makeDesktopItem {
        name = pname;
        desktopName = "Darkest Dungeon";
        genericName = "Loosing your will to live; the game";
        exec = "darkest";
        icon = pname;
        comment = "Darkest Dungeon GoG version";
        categories = ["Game"];
      })
    ];

    unpackCmd = "${unzip}/bin/unzip $src 'data/noarch/game/*' 'data/noarch/support/icon.png' -d . || true";

    sourceRoot = ".";

    installPhase = ''
      mkdir -p $out/share/${pname}
      mkdir -p $out/share/icons/hicolor

      # Only copies this folder since the rest is useless.
      mv data/noarch/game/* $out/share/${pname}

      # Installs the icon.
      mv data/noarch/support/icon.png $out/share/icons/hicolor/${pname}.png

      # Creates the wrapper for the game.
      makeBinaryWrapper $out/share/${pname}/darkest.bin.x86_64 $out/bin/darkest \
        --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath commonDeps}
    '';

    # Metadata
    meta = with lib; {
      description = "The game that would drive you into utter maddness";
      longDescription = "Darkest Dungeon GoG version. Without any DLCs";
      homepage = "https://www.darkestdungeon.com";
      downloadPage = "https://www.gog.com/game/darkest_dungeon";
      license = licenses.unfree;
      mainProgram = "darkest";
      maintainers = with maintainers; [notevil];
      platforms = ["x86_64-linux"];
    };
  }
