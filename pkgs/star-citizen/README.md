# Star Citizen

Installer for [Star Citizen](https://robertsspaceindustries.com/)

## Linux user group

Solutions for common issues can be found on the [linux user group wiki](https://starcitizen-lug.github.io).

## Basic requirements

Make sure `vm.max_map_count` is set to at least 16777216 and `fs.file-max` is set to 524288

```nix
# NixOS configuration for Star Citizen requirements
boot.kernel.sysctl = {
  "vm.max_map_count" = 16777216;
  "fs.file-max" = 524288;
};
```

Currently recommended to have at least 40GB RAM + swap. If you have less than 40GB enable zram.

## Tips

To access the wine control panel please run the following:

```bash
# Adjust WINEPREFIX to your location
# this is the default path
WINEPREFIX=$HOME/Games/star-citizen nix run github:fufexan/nix-gaming#wine-ge -- control
```

### Credits

* [Linux User Group](https://starcitizen-lug.github.io) - A lot of the testing of requirements has been done there
