{ lib
, makeDesktopItem
, symlinkJoin
, writeShellScriptBin

, gamemode
, jdk8
, steam-run
, withSteamRun ? false

, pname ? "technic-launcher"
}:

let
  src = builtins.fetchurl {
    url = "https://launcher.technicpack.net/launcher4/680/TechnicLauncher.jar";
    sha256 = "sha256-NyWHCvz1CrCET8DZ40Y7qXZZTSBuL1bpoou/1Rc05Eg=";
  };

  desktopItems = makeDesktopItem {
    name = pname;
    exec = pname;
    inherit icon;
    comment = "Technic Platform Launcher";
    desktopName = "Technic Launcher";
    categories = "Game;";
  };

  icon = builtins.fetchurl {
    url = "https://worldvectorlogo.com/download/technic-launcher.svg";
    sha256 = "sha256-hZpqxNGCPWDGw1v2y1vMnvo6qGfqI9AfcmU+Q2u/KBc=";
  };


  script = writeShellScriptBin pname ''
    PATH=$PATH:${gamemode} ${if withSteamRun then "${steam-run}/bin/steam-run" else ""} ${gamemode}/bin/gamemoderun ${jdk8}/bin/java -jar ${src}
  '';
in

symlinkJoin {
  name = pname;
  version = "680";
  paths = [ desktopItems script ];

  meta = {
    description = "Minecraft Launcher with support for Technic Modpacks";
    homepage = "https://technicpack.net";
    license = lib.licenses.unfree;
    maintainers = lib.maintainers.fufexan;
    platforms = lib.platforms.linux;
  };
}
