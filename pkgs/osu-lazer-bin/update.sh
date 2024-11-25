#!/usr/bin/env -S nix shell nixpkgs#curl nixpkgs#jq -c bash

info="pkgs/osu-lazer-bin/info.json"
version=$(curl -s "https://api.github.com/repos/ppy/osu/releases/latest" | jq -r '.tag_name')
oldversion=$(jq -r '.version' "$info")
url="https://github.com/ppy/osu/releases/download/${version}/osu.AppImage"

if [ "$oldversion" != "$version" ]; then
  if output=$(nix store prefetch-file "$url" --json); then
    jq --arg version "$version" '.version = $version' <<<"$output" >"$info"
  else
    echo "Failed to fetch new osu!lazer binary, possibly non-release update"
  fi
else
  echo "osu!lazer is up to date."
fi
