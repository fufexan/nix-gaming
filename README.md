<h1 align="center">🎮 nix-gaming</h1>

Gaming related stuff for Nix and NixOS.

See an overview of the flake outputs by running
`nix flake show github:fufexan/nix-gaming`.

## 🗃️ What's in here?

| Package                                                     | Description                                                                                            |
| ----------------------------------------------------------- | ------------------------------------------------------------------------------------------------------ |
| [`faf-client`](./pkgs/faf-client)                           | Forged Alliance Forever client (multiple packages)                                                     |
| [`osu-lazer-bin`](./pkgs/osu-lazer-bin)                     | osu! lazer, extracted from the official AppImage                                                       |
| [`osu-stable`](./pkgs/osu-stable)                           | osu! stable version                                                                                    |
| `rocket-league`                                             | Rocket League from Epic Games                                                                          |
| [`star-citizen`](./pkgs/star-citizen)                       | Star Citizen                                                                                           |
| [`technic-launcher`](./pkgs/technic-launcher)               | Technic Launcher                                                                                       |
| [`wine-discord-ipc-bridge`](./pkgs/wine-discord-ipc-bridge) | Wine-Discord RPC Bridge                                                                                |
| [`wine`](./pkgs/wine)                                       | Multiple Wine packages                                                                                 |
| [`winestreamproxy`](./pkgs/winestreamproxy)                 | Wine-Discord RPC (broken)                                                                              |
| [`northstar-proton`](./pkgs/titanfall/northstar-proton.nix) | Proton build based on TKG's proton-tkg build system to run the Northstar client on Linux and SteamDeck |
| [`viper`](./pkgs/titanfall/viper.nix)                       | Launcher+Updater for Titanfall2 Northstar Client                                                       |

- `legendaryBuilder` is a function that installs games with `legendary-gl`. You
  are expected to log in before using it, with `legendary auth`. The function
  takes an attrset containing at least the attrset `games` which includes the
  games you want installed. Optionally, you can set an `opts` attrset that will
  set the options you set inside for all games listed. You can find a usage
  example in [example.nix](./example.nix).

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
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";

    nix-gaming.url = "github:fufexan/nix-gaming";
  };

  outputs = {self, nixpkgs, ...}@inputs: {
    # set up for NixOS
    nixosConfigurations.HOSTNAME = nixpkgs.lib.nixosSystem {
      specialArgs = {inherit inputs;};
      modules = [
        ./configuration.nix
        # ...
      ];
    };

    # or for Home Manager
    homeConfigurations.HOSTNAME = inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = import nixpkgs {
        system = "x86_64-linux";
        config.allowUnfree = true;
      };

      extraSpecialArgs = {inherit inputs;};

      modules = [
        ./home.nix
        # ...
      ];
    }
  };
}
```

Then, add the package(s):

```nix
{pkgs, inputs, ...}: {
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
  # install packages
  environment.systemPackages = [ # or home.packages
    nix-gaming.packages.${pkgs.hostPlatform.system}.<package>
  ];
}
```

## Modules

Here are some NixOS modules for setting gaming related options.

### Installation

#### Flakes

Assuming you've followed the [Install/Flakes](#️-flakes) instructions, all you
need to do is add the module to your configuration like this:

```nix
{inputs, ...}: {
  imports = [
    inputs.nix-gaming.nixosModules.<module name>
  ];
}
```

Now you can skip to the Usage section of a specific module.

#### Stable

Assuming you've followed the [Install/Nix Stable](#nix-stable) instructions, all
you need to do is add the module to your configuration like this:

```nix
{pkgs, ...}: let
  nix-gaming = /* ... */;
in {
  imports = [
    nix-gaming.nixosModules.<module name>
  ];
}
```

### PipeWire low latency

[PipeWire](https://nixos.wiki/wiki/PipeWire) is a new audio backend that
replaces ALSA, PulseAudio and JACK. It is as low latency as JACK and as easy to
use as Pulse.

This module extends the PipeWire module from Nixpkgs and makes it easy to enable
the low latency settings in a few lines.

#### Usage

After importing the module in your configuration like described above, enable it
along with PipeWire:

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

If you get no sound, you may want to increase `quantum`.

You can calculate the theoretical latency by dividing `quantum` by `rate`
(`48/48000` is exactly 1ms).

### Platform optimizations

[SteamOS](https://store.steampowered.com/steamos) on the steam deck has set some
specific sysctl settings, so that some games can be run at all, or perform
better under certain circumstances.

This module extends the Steam module from Nixpkgs but can be enabled as a
standalone option.

#### Usage

After importing the module in your configuration like described above, enable it
like this:

```nix
{
  programs.steam.platformOptimizations.enable = true;
}
```

## ⚙ Game overrides

Wine-based game derivations were written with versatility in mind.

These arguments can be modified in order to get the desired results.

```nix
{
  wine      ? wine-ge,          # controls the wine package used to run wine games
  wineFlags ? "",               # which flags to run wine with (literal)
  pname     ? "game-name",      # name of the script and package
  location  ? "$HOME/${pname}", # where to install the game/wine prefix
  tricks    ? [],               # which wine tricks to install

  preCommands  ? "",            # run commands before the game is started
  postCommands ? "",            # run commands after the game is closed
}:
```

### `osu-stable` `wine-discord-ipc-bridge` wine overriding

Sometimes you want to override `wine` for various reasons. Here's how to do it:

```nix
{
  environment.systemPackages = let
    gamePkgs = inputs.nix-gaming.packages.${pkgs.hostPlatform.system};
  in [ # or home.packages
    gamePkgs.osu-stable.override rec {
      wine = <your-wine>;
      wine-discord-ipc-bridge = gamePkgs.wine-discord-ipc-bridge.override {inherit wine;}; # or override this one as well
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

Thank you: boppyt - gonX - InfinityGhost - LavaDesu - openglfreak - yusdacra and
to all the contributors and users of this repo!
