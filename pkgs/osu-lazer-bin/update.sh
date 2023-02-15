#!/usr/bin/env -S nix shell nixpkgs#jq nixpkgs#moreutils -c bash

info="pkgs/osu-lazer-bin/info.json"
version=$(jq -r '.pins.osu.version' npins/sources.json)
oldversion=$(jq -r '.version' "$info")
url="https://github.com/ppy/osu/releases/download/${version}/osu.AppImage"

if [ "$oldversion" != "$version" ]; then
  nix store prefetch-file "$url" --json > "$info"
  jq --arg version "$version" '.version = $version' "$info" | sponge "$info"
else
  echo "osu!lazer is up to date."
fi
