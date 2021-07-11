# osu.nix

[osu!](https://osu.ppy.sh)-related stuff for Nix and NixOS. Easily install
everything you need in order to have the best osu! experience.

## What's in here?

Package              | Description
---------------------|---
`osu-stable`         | Default package
`winestreamproxy`    | Wine-Discord RPC
`wine-tkg`           | Wine optimized for games
`discord-ipc-bridge` | Older RPC
`wine-osu`           | Older Wine with osu-only patches

`osu-stable` provides a script that installs/runs osu! automatically, in
addition to a desktop entry.

Installation will take a bit of time. It will download and install about 400MB
of files. In any case, **do not stop the command!**

If anything goes wrong and for some reason osu! won't start, delete the `~/.osu`
directory and re-run `osu-stable`.

`osu-stable` uses a specialized version of `wine`, called `wine-tkg`, tailored
for the best gaming experience. In addition to
[the tkg patches](https://github.com/Frogging-Family/wine-tkg-git),I have added
[openglfreak's patches](https://github.com/openglfreak/wine-tkg-userpatches) and
[gonX's patches](https://drive.google.com/drive/folders/17MVlyXixv7uS3JW4B-H8oS4qgLn7eBw5)
which make everything buttery smooth.

`winestreamproxy` provides bridging between osu! under Wine and Discord running
on Linux.

## Install & Run

It's recommended to set up [Cachix](#cachix) so you don't have to build packages.
```nix
# configuration.nix
{
  nix = {
    binaryCaches = [
      "https://cache.nixos.org"
      ...
      "https://app.cachix.org/cache/osu-nix"
    ];
    binaryCachePublicKeys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      ...
      "osu-nix.cachix.org-1:vn/szRSrx1j0IA/oqLAokr/kktKQzsDgDPQzkLFR9Cg="
    ];
  };
}
```
Now, rebuild your configuration and continue reading for install instructions.

#### If you're not using flakes, [skip to here](#nix-stable).

### Flakes

Add these packages to your `home.packages` or `environment.systemPackages` by
adding `osu-nix` as an input:
```nix
# flake.nix
{
  ...
  inputs.osu-nix.url = github:fufexan/osu.nix;
}
```

Then, add the package(s):
```nix
#
{
  environment.systemPackages = [
    ...
    inputs.osu-nix.defaultPackage.x86_64-linux     # installs osu-stable
    inputs.osu-nix.packages.x86_64-linux.<package> # installs a package
  ];
}
```
Everything is available as an overlay if you prefer that, though your results
will greatly differ from the packages.

### Nix Stable

The following instructions assume you have this repo cloned somewhere.

#### Packages

To install packages with `nix-env`, run
```
cd directory/of/osu.nix
nix-env -if . # to install osu-stable
nix-env -if . -A packages.x86_64-linux.<package> # osu-stable/wine-osu/discord-ipc-bridge
```

To install packages to `environment.systemPackages`, add this in `configuration.nix`:
```nix
let
  osu-nix = import (builtins.fetchTarball "https://github.com/fufexan/osu.nix/archive/master.tar.gz");
in
{
  # import the low latency module
  imports = [
    ...
    "osu-nix/modules/pipewireLowLatency.nix"
  ];
  
  # install packages
  environment.systemPackages = [ # home.packages
    osu-nix.defultPackage.x86_64-linux      # installs osu-stable
    osu-nix.packages.x86_64-linux.<package>
  ];
  
  # enable module (see below)
  services.pipewire = ...;
}
```

## PipeWire low latency

PipeWire is a new audio backend that replaces ALSA, PulseAudio and Jack. It
achieves lower latency than possible previously with Pulse, for lower CPU
overhead.

This module extends the PipeWire module from nixpkgs and makes it easy to
enable the low latency settings from a single line (or more).

Add it as a module to your configuration and enable it along with PipeWire:
```nix
{
  services.pipewire = {
    enable = true;
    # alsa is optional
    alsa.enable = true;
    alsa.support32Bit = true;
    # needed for osu
    pulse.enable = true;

    # the star of the show
    lowLatency.enable = true;

    # defaults (no need to be set unless modified)
    lowLatency = {
      quantum = 64; # usually a power of 2
      rate = 48000;
    };
  };
  
  # make pipewire realtime-capable
  security.rtkit.enable = true;
}
```

If you get no sound, you may want to increase `quantum`, usually to a power of
2 or the prefix of the `rate` (`48/48000` is exactly 1ms).

### Overrides for osu

The osu derivation was written with versatility in mind. There are args that can be modified in order to get the result one wants.
```nix
{
  wine      ? null         # controls the wine package used to run osu
  wineFlags ? null         # which flags to run wine with
  pname     ? "osu-stable" # name of the script and package
  verbose   ? false        # whether to output anything when running osu (verbose by default for the install process)
  location  ? "$HOME/.osu" # where to install the wine prefix
  tricks    ? [ "gdiplus" "dotnet40" "meiryo" ] # which wine tricks to install
  
  # gdiplus - necessary for osu
  # dotnet40 - minimum version needed. if you want to run something like gosumemory, you should use dotnet45, though you'll be on your own
  # meiryo - CJK fonts for map names
}:
```

## Credits & Resources
 
Thank you
- [gonX](https://github.com/gonX)
- [openglfreak](https://github.com/openglfreak)
- [yusdacra](https://github.com/yusdacra)
