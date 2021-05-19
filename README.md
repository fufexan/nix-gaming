# osu.nix

[osu!](https://osu.ppy.sh)-related stuff for Nix and NixOS

## Wine

Wine 6.7 with low-latency audio patches applied. It currently provides the
lowest latency osu! environment on Linux, only limited by your hardware.

Test it in a shell:
```
$ nix shell github:fufexan/osu.nix
$ WINEPREFIX="path/to/osu/install" wine path/to/osu.exe
```
or add it to your `home.packages` or `environment.systemPackages` with
`inputs.osu-nix` after adding it as an input:
```nix
# flake.nix
{
  inputs.osu-nix.url = github:fufexan/osu.nix
  ...
}
```

Also available as an overlay if you prefer that.

**NOTE**: This wine version is available on [Cachix](https://app.cachix.org/cache/fufexan). Add it to your
binary caches to avoid building wine.

## Credits

Thank you
- [gonX](https://github.com/gonX) for providing the wine patch
- [yusdacra](https://github.com/yusdacra) for helping me debug this flake
