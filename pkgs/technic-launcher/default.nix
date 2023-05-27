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
  version = "757";
  src = builtins.fetchurl {
    url = "https://launcher.technicpack.net/launcher4/${version}/TechnicLauncher.jar";
    sha256 = "038dq2gm0v707pjwbg13vyjx56mh0yqv7g9c9hp2m58k8rqhaaxr";
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
