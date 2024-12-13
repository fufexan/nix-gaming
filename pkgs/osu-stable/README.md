# osu!stable

`osu-stable` provides a script that installs/runs osu! automatically, in
addition to a desktop entry.
Installation will take a bit of time. It will download and install about 400MB
of files. In any case, **do not stop the command!**

If anything goes wrong and for some reason osu! won't start, delete the `~/.osu`
directory and re-run `osu-stable`.

## Additional Overrides

This package has the following additional overrides:

- `protonPath` Proton compatibility tool if umu is used.
Defaults to [`proton-osu-bin`](../proton-osu-bin/README.md).
- `protonVerbs`
