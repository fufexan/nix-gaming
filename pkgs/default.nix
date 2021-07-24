{ inputs }:
final: prev: {
  osu-stable = prev.callPackage ./osu-stable {
    wine = final.wine-tkg;
    winetricks = prev.winetricks.override { wine = final.wine-tkg; };
    inherit (final) winestreamproxy;
  };

  winestreamproxy = prev.callPackage ./winestreamproxy { wine = final.wine-tkg; };

  wine-tkg = prev.callPackage ./wine-tkg {
    wine =
      if prev.system == "x86_64-linux"
      then final.wineWowPackages.unstable
      else final.wineUnstable;
    inherit (inputs) tkgPatches oglfPatches;
  };

  # --- deprecated ---
  discord-ipc-bridge = prev.pkgsCross.mingw32.callPackage ./discord-ipc-bridge { dib = inputs.discord-ipc-bridge; };

  wine-osu =
    let
      nwo = inputs.nixpkgs-wine-osu.legacyPackages.${prev.system};
    in
    nwo.callPackage ./wine-osu { wine = nwo.wineUnstable; };
}
