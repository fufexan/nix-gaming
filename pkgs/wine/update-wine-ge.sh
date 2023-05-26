#!/usr/bin/env -S nix shell nixpkgs#npins -c bash

REPO_OWNER="GloriousEggroll"
REPO_NAME="proton-wine"

# Get branch names
branches=$(curl -s "https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/branches?per_page=10000" | grep -oP '(?<="name": ")[^"]+')

# Initialize variables
latest_major=0
latest_minor=0

# Find the latest version
for branch in $branches; do
  if [[ $branch =~ ^Proton([0-9]+)-([0-9]+) ]]; then
    major=${BASH_REMATCH[1]}
    minor=${BASH_REMATCH[2]}
    if (( major > latest_major )) || (( major == latest_major && minor > latest_minor )); then
      latest_major=$major
      latest_minor=$minor
      latest_branch=$branch
    fi
  fi
done

npins add github -b "$latest_branch" "$REPO_OWNER" "$REPO_NAME"
