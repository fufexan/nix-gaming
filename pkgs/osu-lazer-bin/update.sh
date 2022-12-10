#!/usr/bin/env nix-shell
#!nix-shell -i bash -p jq moreutils

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
