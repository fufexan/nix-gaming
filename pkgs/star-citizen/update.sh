#!/usr/bin/env nix-shell
#! nix-shell -i bash -p curl yq-go jq

INFO="pkgs/star-citizen/info.json"

VERSION="$(curl -s 'https://install.robertsspaceindustries.com/rel/2/latest.yml' | yq -r '.version')"

url="https://install.robertsspaceindustries.com/rel/2/RSI%20Launcher-Setup-$VERSION.exe"

HASH="$(nix store prefetch-file "$url" --name "RSI-Launcher-Setup-$VERSION.exe" --json | jq -r .hash)"

jq -n \
        --arg version "$VERSION" \
        --arg url "$url" \
        --arg hash "$HASH" \
        '{version: $version, url: $url, hash: $hash}' >"$INFO"
