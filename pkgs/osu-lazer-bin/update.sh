#!/usr/bin/env -S nix shell nixpkgs#curl nixpkgs#jq -c bash

set -eu

info="pkgs/osu-lazer-bin/info.json"
releases="$(curl -fsSL "https://api.github.com/repos/ppy/osu/releases")"

for releaseStream in $(jq -r 'keys[]' "$info"); do
  query=$(jq -r ".$releaseStream.query" "$info")
  # Sort descending by creation date in case GitHub releases order gets messed up
  version=$(jq -r "sort_by(.created_at) | reverse | $query" <<<"$releases")
  oldversion=$(jq -r ".$releaseStream.version" "$info")
  url="https://github.com/ppy/osu/releases/download/${version}/osu.AppImage"

  if [ "$oldversion" != "$version" ]; then
    output=$(mktemp)
    if nix store prefetch-file "$url" --json > "$output"; then
      newinfo=$(mktemp)
      # Merges object of release stream with output from Nix store prefetch
      jq -s --arg version "$version" ".[0].$releaseStream = .[0].$releaseStream + .[1] | .[0] | .$releaseStream.version = \$version" "$info" "$output" > "$newinfo"
      cp -f "$newinfo" "$info"
      rm "$newinfo"
    else
      echo "osu!lazer ($releaseStream) has a non-release update"
    fi
    rm "$output"
  else
    echo "osu!lazer ($releaseStream) is up to date."
  fi
done

