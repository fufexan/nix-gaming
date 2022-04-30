# nix-gaming

Gaming related stuff for Nix and NixOS.

## What's in here?

Package                   | Description
--------------------------|---
`osu-lazer-bin`           | osu! lazer, extracted from the official AppImage
`osu-stable`              | osu! stable version
`rocket-league`           | Rocket League from Epic Games
`technic-launcher`        | Technic Launcher
`wine-discord-ipc-bridge` | Wine-Discord RPC Bridge
`wine-osu`                | Wine optimized for low latency
`wine-tkg`                | Wine optimized for games
`winestreamproxy`         | Wine-Discord RPC (broken)

* `legendaryBuilder` is a function that installs games with `legendary-gl`. You
are expected to log in before using it, with `legendary auth`.
The function takes an attrset containing at least the attrset `games` which
includes the games you want installed. Optionally, you can set an `opts`
attrset that will set the options you set inside for all games listed.

You can find a usage example in [example.nix](./example.nix).

* `osu-lazer-bin` is an osu!lazer build that is extracted from official binary
AppImage releases in order to preserve multiplayer functions.

* `osu-stable` provides a script that installs/runs osu! automatically, in
addition to a desktop entry.
Installation will take a bit of time. It will download and install about 400MB
of files. In any case, **do not stop the command!**
If anything goes wrong and for some reason osu! won't start, delete the `~/.osu`
directory and re-run `osu-stable`.

* `technic-launcher` will guide you through the install process, just like it
normally would. Some modpacks will complain about libraries, and that is
expected. In such cases you may want to enable the `withSteamRun = true;`
override flag. This will run `technic-launcher` with `steam-run` and prevent
those errors.

* `wine-discord-ipc-bridge` provides bridging between games under Wine and
Discord running on Linux.

* `wine-osu` is wine-staging, with patches applied to make it low-latency.
The patches can be found
[here](https://drive.google.com/drive/folders/17MVlyXixv7uS3JW4B-H8oS4qgLn7eBw5).

* `wine-tkg` is a special wine version, tailored for the best gaming experience.
It consists of a wine tree generated with
[the tkg patches](https://github.com/Frogging-Family/wine-tkg-git).

* `winestreamproxy` provides bridging between games under Wine and Discord
running on Linux. (**currently broken, help with building would be appreciated**)

## Install & Run

It's recommended to set up [Cachix](https://app.cachix.org/cache/nix-gaming) so
you don't have to build packages.
```nix
# configuration.nix
{
  nix.settings = {
    substituters = [ "https://nix-gaming.cachix.org" ];
    trusted-public-keys = [ "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4=" ];
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

Also, add `inputs` or `nix-gaming` to `specialArgs` when building your system
config, or to `extraSpecialArgs` when building your Home Manager configuration.

Then, add the package(s):
```nix
{ pkgs, config, inputs, ... }:

{
  environment.systemPackages = [ # or home.packages
    inputs.nix-gaming.packages.${pkgs.system}.<package> # installs a package
  ];
}
```

If you want to install packages to your profile instead, do it like this
```
  nix profile install github:fufexan/nix-gaming#<package>
```

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
  
  preCommands  ? "" # run commands before the game is started
  postCommands ? "" # run commands after the game is closed
}
```

### `osu-stable` `wine-discord-ipc-bridge` wine overriding

Sometimes you want to override `wine` for various reasons. Here's how to do it:
```nix
{
  environment.systemPackages = [ # or home.packages
    inputs.nix-gaming.packages.${pkgs.system}.osu-stable.override rec {
      wine = <your-wine>;
      wine-discord-ipc-bridge = wine-discord-ipc-bridge.override {inherit wine;}; # or override this one as well
    };
  ];
}
```

## Tips

In order to get the most performance out of your machine, you could use the
following tweaks:

- custom/gaming kernel: `linux_xanmod` is the recommended one for games, since
it provides many patches that aid wine and other games. It also provides a
better desktop experience due to its PREEMPTive nature and tickless scheduler.
- [gamemode](https://github.com/FeralInteractive/gamemode): lets you achieve
lower nice values and higher realtime privileges at game start. It can either
detect games or be told to start with `gamemode-run`.

## Credits & Resources
 
Thank you
- [boppyt](https://github.com/boppyt)
- [gonX](https://github.com/gonX)
- [InfinityGhost](https://github.com/InfinityGhost)
- [LavaDesu](https://github.com/LavaDesu)
- [openglfreak](https://github.com/openglfreak)
- [yusdacra](https://github.com/yusdacra)
