#!/usr/bin/env -S nix shell .#npins nixpkgs#jq -c bash

REPO_OWNER="CachyOS"
REPO_NAME="wine-cachyos"

# Get the latest branch using jq
latest_branch=$(curl -s "https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/branches?per_page=10000" | \
  jq -r '
    [.[] |
     (.name | capture("^cachyos_(?<major>[0-9]+)\\.(?<minor>[0-9]+)_(?<date>[0-9]+)/main$")) as $parts |
     select($parts) |
     {
       name: .name,
       major: ($parts.major | tonumber),
       minor: ($parts.minor | tonumber),
       date: ($parts.date | tonumber)
     }
    ] |
    max_by([.major, .minor, .date]) |
    .name
  ')

npins add github --frozen -b "$latest_branch" "$REPO_OWNER" "$REPO_NAME"
