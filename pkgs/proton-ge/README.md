# Proton-GE

To use `proton-ge`, you must add it to your steam compatibility tools path.

A simple implementation would be to use the overlay:

```nix
nixpkgs.overlays = [
    (_: prev: {
        steam = prev.steam.override {
            extraProfile = "export STEAM_EXTRA_COMPAT_TOOLS_PATHS='${inputs.nix-gaming.packages.${pkgs.system}.proton-ge}'";
        };
    })
];
```

More info can be found [here](https://github.com/NixOS/nixpkgs/issues/73323#issuecomment-1079939987).
