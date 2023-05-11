<h1 align="center">nix-gaming</h1>

Gaming related stuff for Nix and NixOS.

See an overview of the flake outputs by running
`nix flake show github:fufexan/nix-gaming`.

## 🗃️ What's in here?

Package                                                     | Description
------------------------------------------------------------|------------
[`faf-client`](./pkgs/faf-client)                           | Forged Alliance Forever client (using the official binary build)
[`faf-client-unstable`](./pkgs/faf-client)                  | Same as above, but use unstable version if available
[`osu-lazer-bin`](./pkgs/osu-lazer-bin)                     | osu! lazer, extracted from the official AppImage
[`osu-stable`](./pkgs/osu-stable)                           | osu! stable version
`rocket-league`                                             | Rocket League from Epic Games
[`technic-launcher`](./pkgs/technic-launcher)               | Technic Launcher
[`wine-discord-ipc-bridge`](./pkgs/wine-discord-ipc-bridge) | Wine-Discord RPC Bridge
[`wine-ge`](./pkgs/wine)                                    | Wine version of Proton-GE
[`wine-osu`](./pkgs/wine)                                   | Wine optimized for low latency
[`wine-tkg`](./pkgs/wine)                                   | Wine optimized for games
[`winestreamproxy`](./pkgs/winestreamproxy)                 | Wine-Discord RPC (broken)
[`proton-ge`](./pkgs/proton-ge)                             | Custom build of Proton with the most recent bleeding-edge Proton Experimental WINE

* `legendaryBuilder` is a function that installs games with `legendary-gl`. You
are expected to log in before using it, with `legendary auth`.
The function takes an attrset containing at least the attrset `games` which
includes the games you want installed. Optionally, you can set an `opts`
attrset that will set the options you set inside for all games listed.
You can find a usage example in [example.nix](./example.nix).

## Install & Run

It's recommended to set up [Cachix](https://app.cachix.org/cache/nix-gaming) so
you don't have to build packages (most useful for wine).
```nix
# configuration.nix
{
  nix.settings = {
    substituters = ["https://nix-gaming.cachix.org"];
    trusted-public-keys = ["nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="];
  };
}
```
Now, rebuild your configuration and continue reading for install instructions.

#### If you're not using flakes, [go here](#nix-stable).

### ❄️ Flakes

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
{pkgs, config, inputs, ...}: {
  environment.systemPackages = [ # or home.packages
    inputs.nix-gaming.packages.${pkgs.system}.<package> # installs a package
  ];
}
```

If you want to install packages to your profile instead, do it like this
```console
  nix profile install github:fufexan/nix-gaming#<package>
```

Everything is available as an overlay if you prefer that, though your results
may greatly differ from the packages.

### Nix Stable

To install packages to `environment.systemPackages`, add this in
`configuration.nix`:
```nix
{pkgs, ...}: let
  nix-gaming = import (builtins.fetchTarball "https://github.com/fufexan/nix-gaming/archive/master.tar.gz");
in {
  # import the low latency module
  imports = [
    ...
    "${nix-gaming}/modules/pipewireLowLatency.nix"
  ];
  
  # install packages
  environment.systemPackages = [ # or home.packages
    nix-gaming.packages.${pkgs.hostPlatform.system}.<package>
  ];
  
  # enable module (see below)
  services.pipewire = ...;
}
```

## PipeWire low latency

[PipeWire](https://nixos.wiki/wiki/PipeWire) is a new audio backend that
replaces ALSA, PulseAudio and JACK. It is as low latency as JACK and as easy to
use as Pulse.

This module extends the PipeWire module from Nixpkgs and makes it easy to enable
the low latency settings in a few lines.

Import the module in your configuration and enable it along with PipeWire:
```nix
{
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;

    lowLatency = {
      # enable this module      
      enable = true;
      # defaults (no need to be set unless modified)
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

### ⚙ Game overrides

The game derivations were written with versatility in mind. There are arguments
that can be modified in order to get the desired result.
```nix
{
  wine      ? wine-tkg,         # controls the wine package used to run wine games
  wineFlags ? null,             # which flags to run wine with
  pname     ? "game-name",      # name of the script and package
  location  ? "$HOME/${pname}", # where to install the game/wine prefix
  tricks    ? null,             # which wine tricks to install

  preCommands  ? "",            # run commands before the game is started
  postCommands ? "",            # run commands after the game is closed
}:
```

### `osu-stable` `wine-discord-ipc-bridge` wine overriding

Sometimes you want to override `wine` for various reasons. Here's how to do it:
```nix
{
  environment.systemPackages = let
    nix-gaming = inputs.nix-gaming.packages.${pkgs.hostPlatform.system};
  in [ # or home.packages
    nix-gaming.osu-stable.override rec {
      wine = <your-wine>;
      wine-discord-ipc-bridge = nix-gaming.wine-discord-ipc-bridge.override {inherit wine;}; # or override this one as well
    };
  ];
}
```

## 📝 Tips

In order to get the most performance out of your machine, you could use the
following tweaks:

- custom/gaming kernel: `linux_xanmod` is the recommended one for games, since
it provides many patches that aid wine and other games. It also provides a
better desktop experience due to its preemptive build and tickless scheduler.
- [gamemode](https://github.com/FeralInteractive/gamemode): lets you achieve
lower nice values and higher realtime privileges at game start. It can either
detect games or be started with `gamemode-run`.

## 👥 Credits & Resources
 
Thank you: boppyt - gonX - InfinityGhost - LavaDesu - openglfreak - yusdacra
and to all the contributors and users of this repo!
