{
  lib,
  makeDesktopItem,
  symlinkJoin,
  writeShellScriptBin,
  gamemode,
  jdk8,
  steam-run,
  withSteamRun ? false,
  pname ? "technic-launcher",
}: let
  src = builtins.fetchurl {
    url = "https://launcher.technicpack.net/launcher4/725/TechnicLauncher.jar";
    sha256 = "04jgk6cpdq2jdjlzb3f6ycjm7gf91gmkwfcj779fygfs4pf9s9dr";
  };

  desktopItems = makeDesktopItem {
    name = pname;
    exec = pname;
    inherit icon;
    comment = "Technic Platform Launcher";
    desktopName = "Technic Launcher";
    categories = ["Game"];
  };

  icon = builtins.fetchurl {
    url = "https://cdn.freebiesupply.com/logos/large/2x/technic-launcher-logo-png-transparent.png";
    sha256 = "0zav6hk3m8gyirz2qwg6f08d4z4ijh3bbw09p9y6cgihzwsmv0f1";
  };

  script = writeShellScriptBin pname ''
    PATH=$PATH:${gamemode} ${
      if withSteamRun
      then "${steam-run}/bin/steam-run"
      else ""
    } ${gamemode}/bin/gamemoderun ${jdk8}/bin/java -jar ${src}
  '';
in
  symlinkJoin {
    name = pname;
    version = "725";
    paths = [desktopItems script];

    meta = {
      description = "Minecraft Launcher with support for Technic Modpacks";
      homepage = "https://technicpack.net";
      license = lib.licenses.unfree;
      maintainers = lib.maintainers.fufexan;
      platforms = lib.platforms.linux;
    };
  }
