# osu.nix

[osu!](https://osu.ppy.sh)-related stuff for Nix and NixOS. Easily install
everything you need in order to have the best osu! experience.

The following instructions assume you use [flakes](https://nixos.wiki/wiki/Flakes).
If you don't (or you're not sure), skip to [here](#nix-stable), but you may
want to read everything until [Install](#install) for context.

## App & Packages

The default app automatically installs osu! to `~/.osu`, then runs it:
```
nix run github:fufexan/osu.nix
```
The app is powered by the `osu-stable` package, which provides a script that
installs/runs osu! automatically.

This will take a bit of time, depending on your internet speed. It will download
about 400MB of files and install them. In any case, **do not stop the command!**

If anything goes wrong and for some reason osu! won't start, delete the `~/.osu`
directory and re-run `osu-stable`.

`osu-stable` itself uses a specialized version of `wine`, called `wine-osu`. It
is tailored for the best osu! experience. It is patched to have low audio
latency and to prevent crashes.

On top of everything, there's `discord-ipc-bridge` which provides bridging
between osu! under wine and Discord running on Linux. In `osu-stable`, it's installed
as a Windows service that runs automatically when you start osu!.

### Package list:
- `osu-stable` (default package)
- `discord-ipc-bridge`
- `wine-osu`

### Install

It's recommended to set up [Cachix](#cachix) so you don't have to build wine.

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
# configuration.nix / home.nix
{
  environment.systemPackages = [
    ...
    inputs.osu-nix.defaultPackage.x86_64-linux     # installs osu-stable
    inputs.osu-nix.packages.x86_64-linux.<package> # installs a package
  ];
}
```

Everything is available as an overlay if you prefer that.

### Overrides for osu

The osu derivation was written with versatility in mind. There are args that can be modified in order to get the result one wants.
```nix
{
  wine      ? wine-osu     # controls the wine package used to run osu
  wineFlags ? null         # which flags to run wine with
  pname     ? "osu-stable" # name of the script and package
  verbose   ? false        # whether to output anything when running osu (verbose by default for the install process)
  location  ? "$HOME/.osu" # where to install the wine prefix
  tricks    ? [ "gdiplus" "dotnet40" "meiryo" ] # which tricks to install
  # gdiplus - necessary for osu
  # dotnet40 - minimum version needed. if you want to run something like gosumemory, you should use dotnet45, though you'll be on your own
  # meiryo - CJK fonts for map names
}:
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
      quantum = 32; # usually a power of 2
      rate = 48000;
    };
  };
  
  # make pipewire realtime-capable
  security.rtkit.enable = true;
}
```

If you get no sound, you may want to increase `quantum`, usually to a power of
2 or the prefix of the `rate` (`48/48000` is exactly 1ms).

## Nix Stable

The following instructions assume you have this repo cloned somewhere.
It's recommended to set up [Cachix](#cachix).

### Packages

To install packages with `nix-env`, run
```
cd path/to/osu.nix
nix-env -if . # to install osu-stable
nix-env -if . -A packages.x86_64-linux.<package> # osu-stable/wine-osu/discord-ipc-bridge
```

To add them to your `environment.systemPackages` or `home.packages`, add this in
any of those locations:
```nix
let
  osu-nix = import (builtins.fetchTarball "https://github.com/fufexan/osu.nix/archive/master.tar.gz");
in
{
  environment.systemPackages = [ # home.packages
    osu-nix.defultPackage.x86_64-linux      # installs osu-stable
    osu-nix.packages.x86_64-linux.<package> # osu-stable/wine-osu/discord-ipc-bridge
  ];
}
```

### Module

```nix
# configuration.nix
let
  osu-nix = builtins.fetchTarball "https://github.com/fufexan/osu.nix/archive/master.tar.gz";
in
{
  imports = [
    ...
    "osu-nix/modules/pipewireLowLatency.nix"
  ];

  services.pipewire = ...;
}
```

**NOTE**: The above snippets weren't tested (as they won't work with flakes) but they
should work fine. Feel free to open an issue if there are any problems.

### Cachix

To allow you to download the already-built version of wine and
discord-ipc-bridge, you need to add this repo's Cachix to your
binaryCaches **before** trying to install this repo's packages:
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
Now, rebuild your configuration and add your preferred packages.

## Credits & Resources
 
Thank you
- [gonX](https://github.com/gonX) for providing the
[pulse patch](https://drive.google.com/drive/folders/17MVlyXixv7uS3JW4B-H8oS4qgLn7eBw5)
- [openglfreak](https://github.com/openglfreak) for provivding the
[secur32 patch](https://github.com/openglfreak/wine-tkg-userpatches/blob/next/patches/0010-crypto/ps0004-secur32-Fix-crash-from-invalid-context-in-InitializeSecurityConte.patch)
- [yusdacra](https://github.com/yusdacra) for helping me debug this flake
