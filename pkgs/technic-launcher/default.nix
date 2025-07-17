{
  lib,
  fetchurl,
  makeDesktopItem,
  symlinkJoin,
  writeShellScriptBin,
  gamemode,
  jdk8,
  steam-run,
  withSteamRun ? false,
  pname ? "technic-launcher",
}: let
  info = builtins.fromJSON (builtins.readFile ./info.json);
  inherit (info) version;
  src = fetchurl {
    inherit (info) url hash;
  };

  desktopItems = makeDesktopItem {
    name = pname;
    exec = pname;
    inherit icon;
    comment = "Technic Platform Launcher";
    desktopName = "Technic Launcher";
    categories = ["Game"];
  };

  icon = fetchurl {
    # original url = "https://cdn.freebiesupply.com/logos/large/2x/technic-launcher-logo-png-transparent.png";
    url = "https://user-images.githubusercontent.com/36706276/203341849-0b049d7a-8c00-4ff1-b916-1a8aacee7ffb.png";
    sha256 = "0p18sfwaral8f6f5h9r5y9sxrzij2ks9zzyhfmzjldldladrwznq";
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
    name = "${pname}-${version}";
    paths = [desktopItems script];

    meta = {
      description = "Minecraft Launcher with support for Technic Modpacks";
      homepage = "https://technicpack.net";
      license = lib.licenses.unfree;
      maintainers = with lib.maintainers; [fufexan];
      platforms = lib.platforms.linux;
    };
  }
