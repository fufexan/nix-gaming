# osu.nix

osu!-related stuff for Nix and NixOS

## Wine

Test it in a shell:
```
$ nix shell github:fufexan/osu.nix
$ wine path/to/osu.exe
```
or add it to your `home.packages` or `environment.systemPackages` with
`inputs.wine-osu` after adding it as an input.

Also available as an overlay if you prefer that.
