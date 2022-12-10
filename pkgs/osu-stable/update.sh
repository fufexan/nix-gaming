#!/usr/bin/env bash

info=pkgs/osu-stable/info.json
url="https://m1.ppy.sh/r/osu!install.exe"

nix store prefetch-file "$url" --name "osuinstall.exe" --json > "$info"
