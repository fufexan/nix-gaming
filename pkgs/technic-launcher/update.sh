#!/usr/bin/env nix-shell
#! nix-shell -i bash -p curl jq

info="pkgs/technic-launcher/info.json"

current_version=""
if [ -f "$info" ]; then
    current_version=$(jq -r '.version' "$info")
fi

release=$(curl -s 'https://api.technicpack.net/launcher/version/stable4')

version="4.$(jq -r '.build' <<<"$release")"

if [ "$current_version" != "$version" ]; then
    url="$(jq -r '.url.jar' <<<"$release")"
    hash=$(nix store prefetch-file "$url" --json | jq -r .hash)
    
    jq -n \
        --arg version "$version" \
        --arg url "$url" \
        --arg hash "$hash" \
        '{version: $version, url: $url, hash: $hash}' >"$info"
fi
