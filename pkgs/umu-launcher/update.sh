#!/usr/bin/env -S nix shell nixpkgs#curl nixpkgs#jq -c bash

set -eux

info="pkgs/umu-launcher/info.json"
rev=$(jq -r '.pins."umu-launcher".revision' npins/sources.json)
oldrev=$(jq -r '.revision' "$info")

url="https://api.github.com/repos/Open-Wine-Components/umu-launcher/commits/$rev"

if [ "$oldrev" != "$rev" ]; then
  output=$(curl --silent "$url")
  rev_date_raw="$(jq -r '.commit.author.date' <<<"$output")"
  rev_date=${rev_date_raw//[^0-9]/}

  jq --null-input \
    --arg lastModifiedDate "$rev_date" \
    --arg revision "$rev" \
    '.lastModifiedDate = $lastModifiedDate | .revision = $revision' >"$info"
fi
