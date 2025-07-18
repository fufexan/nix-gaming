#!/usr/bin/env -S nix shell .#npins -c bash
for pkg in wine-tkg{,-ntsync} ; do
  src=$(npins get-path $pkg)
  install -D "$src/VERSION" pkgs/wine/$pkg/VERSION
done
