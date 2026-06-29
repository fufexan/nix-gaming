# Rocket League

Installer for Epic Games version of [Rocket League](https://www.rocketleague.com/). [legendary](https://github.com/derrod/legendary) is used for authentication and launching the game.

## How to use
Make sure you have logged in with legendary, you don't have to have legendary available in your system, if that is the case, you can temporarily enable it and log in;
```bash
$ nix shell nixpkgs#legendary-gl
$ legendary auth
```

After logging in you can add rocket-league to your `home.packages` or `environment.systemPackages` by adding `nix-gaming` to your inputs.

After executing `nixos-rebuild switch` you should have `rocket-league` available to your system.

# Bakkesmod

Bakkesmod would only work with EAC disabled, however an [upstream bug](https://github.com/Open-Wine-Components/umu-launcher/issues/194) prevents running bakkesmod and rocket-league at the same time, so for the time being bakkesmod does not work through nix-gaming.

## Enabling bakkesmod

You can enable bakkesmod by overriding rocket-league like that;
```nix
  home-manager.users.emrebicer = {
    home.packages = with pkgs; [
      (inputs.nix-gaming.packages.${pkgs.system}.rocket-league.override {
        enableBakkesmod = true;
        enableEAC = false;
      })
    ];
  };
```

After rebuilding, `bakkesmod` will be available to your system, just run bakkesmod once to install it, don't create a desktop item and finish the installation. Then you should be able to run bakkesmod and Rocket League at the same time. If bakkesmod does not inject automatically make sure to disable `Safe mode` through bakkesmod settings.
