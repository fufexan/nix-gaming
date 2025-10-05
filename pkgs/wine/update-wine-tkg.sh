#!/usr/bin/env -S nix shell .#npins -c bash
src=$(npins get-path wine-tkg)
install -D "$src/VERSION" pkgs/wine/wine-tkg/VERSION
