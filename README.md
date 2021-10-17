# nix-gaming

Gaming related stuff for Nix and NixOS.

## What's in here?

Package              | Description
---------------------|---
`osu-stable`         | osu! stable version
`rocket-league`      | Rocket League from Epic Games
`technic-launcher`   | Technic Launcher
`winestreamproxy`    | Wine-Discord RPC
`wine-tkg`           | Wine optimized for games

* `osu-stable` provides a script that installs/runs osu! automatically, in
addition to a desktop entry.
Installation will take a bit of time. It will download and install about 400MB
of files. In any case, **do not stop the command!**
If anything goes wrong and for some reason osu! won't start, delete the `~/.osu`
directory and re-run `osu-stable`.

* `rocket-league` relies on `legendary-gl`, which expects you to log in. It's
best to do that before running RL, by adding `legendary-gl` in a nix shell and
running `legendary auth`.

* `technic-launcher` will guide you through the install process, just like it
normally would. Some modpacks will complain about libraries, and that is
expected. In such cases you may want to enable the `withSteamRun = true;`
override flag. This will run `technic-launcher` with `steam-run` and prevent
those errors.

* `wine-tkg` is a special wine version, tailored for the best gaming experience.
In addition to [the tkg patches](https://github.com/Frogging-Family/wine-tkg-git),
I have added [openglfreak's patches](https://github.com/openglfreak/wine-tkg-userpatches) and
[gonX's patches](https://drive.google.com/drive/folders/17MVlyXixv7uS3JW4B-H8oS4qgLn7eBw5)
which make everything buttery smooth.
**NOTE:** I was not aware of this until now, but it's very likely that the built
`wine` isn't actually `tkg`. Because of the way nixpkgs handles `patches` currently,
I will have to find a better way to patch everything in.

* `winestreamproxy` provides bridging between games under Wine and Discord
running on Linux.

## Install & Run

It's recommended to set up [Cachix](https://app.cachix.org/cache/nix-gaming) so
you don't have to build packages.
```nix
# configuration.nix
{
  nix = {
    binaryCaches = [ "https://nix-gaming.cachix.org" ];
    binaryCachePublicKeys = [ "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4=" ];
  };
}
```
Now, rebuild your configuration and continue reading for install instructions.

#### If you're not using flakes, [skip to here](#nix-stable).

### Flakes

Add these packages to your `home.packages` or `environment.systemPackages` by
adding `nix-gaming` as an input:
```nix
# flake.nix
{
  inputs.nix-gaming.url = github:fufexan/nix-gaming;
}
```

Then, add the package(s):
```nix
#
{
  environment.systemPackages = [ # or home.packages
    inputs.nix-gaming.packages.x86_64-linux.<package> # installs a package
  ];
}
```

If you want to install packages to your profile instead, do it like this
```
  nix profile install github:fufexan/nix-gaming#<package>
```
**NOTE**: the above snippet won't work if you use Home-Manager. You can use the
old `nix-env` syntax.

Everything is available as an overlay if you prefer that, though your results
may greatly differ from the packages.

### Nix Stable

The following instructions assume you have this repo cloned somewhere.

#### Packages

To install packages with `nix-env`, run
```
cd directory/of/nix-gaming
nix-env -if . -A packages.x86_64-linux.<package>
```

To install packages to `environment.systemPackages`, add this in
`configuration.nix`:
```nix
let
  nix-gaming = import (builtins.fetchTarball "https://github.com/fufexan/nix-gaming/archive/master.tar.gz");
in
{
  # import the low latency module
  imports = [
    ...
    "nix-gaming/modules/pipewireLowLatency.nix"
  ];
  
  # install packages
  environment.systemPackages = [ # home.packages
    nix-gaming.packages.x86_64-linux.<package>
  ];
  
  # enable module (see below)
  services.pipewire = ...;
}
```

## PipeWire low latency

[PipeWire](https://nixos.wiki/wiki/PipeWire) is a new audio backend that
replaces ALSA, PulseAudio and Jack. It achieves lower latency than possible
previously with Pulse, for lower CPU overhead.

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
      quantum = 64;
      rate = 48000;
    };
  };
  
  # make pipewire realtime-capable
  security.rtkit.enable = true;
}
```

If you get no sound, you may want to increase `quantum`, usually to an even
number or the prefix of the `rate` (`48/48000` is exactly 1ms).

### Game overrides

The game derivations were written with versatility in mind. There are args that
can be modified in order to get the result one wants.
```nix
{
  wine      ? wine-tkg         # controls the wine package used to run wine games
  wineFlags ? null             # which flags to run wine with
  pname     ? "game-name"      # name of the script and package
  location  ? "$HOME/${pname}" # where to install the game/wine prefix
  tricks    ? null             # which wine tricks to install
}
```

## Tips

In order to get the most performance out of your machine, you could use the
following tweaks:

- custom/gaming kernel: `linux_xanmod` is the recommended one for games, since
it provides many patches that aid wine and other games.
**NOTE:** Xanmod is not preferred on laptops and other power-constrained devices,
as the tick scheduler draws a lot of power (at least 3W alone).
- [gamemode](https://github.com/FeralInteractive/gamemode): lets you achieve lower
nice values and higher realtime privileges at game start. It can either detect
games or be told to start with `gamemode-run`.
- `pw-jack`: can force games such as `osu-lazer` to a lower quant value which provides
lower latencies than using the `pulse` backend.

## Credits & Resources
 
Thank you
- [gonX](https://github.com/gonX)
- [openglfreak](https://github.com/openglfreak)
- [yusdacra](https://github.com/yusdacra)
