# Titanfall Utilities & Compatibility Tools

## Viper

Viper is a launcher/updater for Titanfall2 Northstar Client. The usage is simple, add it to your system packages
and run `viper` in your terminal. The launcher will guide you through the rest of the process.

## NorthstarProton

NorthstarProton is a Proton build based on TKG's proton-tkg build system to run the Northstar client on
Linux and SteamDeck, along with some enhancements out-of-the-box.

To use `northstar-proton`, you must add it to your steam compatibility tools path.

A simple implementation would be to use the overlay, similar to proton-ge:

```nix
nixpkgs.overlays = [
    (_: prev: {
        steam = prev.steam.override {
            extraProfile = "export STEAM_EXTRA_COMPAT_TOOLS_PATHS='${inputs.nix-gaming.packages.${pkgs.stdenv.hostPlatform.system}.northstar-proton}'";
        };
    })
];
```

## FlightCore

FlightCore is a launcher/updater for Titanfall2 Northstar Client. Currently not available due to a bug with Tauri disallowing extracted AppImages.
