#!/usr/bin/env -S nix shell nixpkgs#jq -c bash

info="pkgs/osu-lazer-bin/info.json"
version=$(jq -r '.pins.osu.version' npins/sources.json)
oldversion=$(jq -r '.version' "$info")
url="https://github.com/ppy/osu/releases/download/${version}/osu.AppImage"

if [ "$oldversion" != "$version" ]; then
  if output=$(nix store prefetch-file "$url" --json); then
    jq --arg version "$version" '.version = $version' <<<"$output" >"$info"
  else
    echo "osu!lazer has a non-release update"
  fi
else
  echo "osu!lazer is up to date."
fi
