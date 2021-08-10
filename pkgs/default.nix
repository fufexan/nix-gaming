{ inputs }:
final: prev: {
  wowtricks = prev.winetricks.override { wine = final.wine-tkg; };

  osu-stable = prev.callPackage ./osu-stable {
    wine = final.wine-tkg;
    winetricks = final.wowtricks;
    inherit (final) winestreamproxy;
  };

  rocket-league = prev.callPackage ./rocket-league {
    wine = final.wine-tkg;
    winetricks = final.wowtricks;
  };

  technic-launcher = prev.callPackage ./technic-launcher { };

  winestreamproxy = prev.callPackage ./winestreamproxy { wine = final.wine-tkg; };

  wine-tkg = prev.callPackage ./wine-tkg {
    wine =
      if prev.system == "x86_64-linux"
      then final.wineWowPackages.unstable
      else final.wineUnstable;
    inherit (inputs) tkgPatches oglfPatches;
  };
}
