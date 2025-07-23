#!/usr/bin/env -S nix shell .#npins -c bash

REPO_OWNER="CachyOS"
REPO_NAME="wine-cachyos"

# Get branch names
branches=$(curl -s "https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/branches?per_page=10000" | grep -oP '(?<="name": ")[^"]+')

# Initialize variables
latest_major=0
latest_minor=0
latest_date=0

# Find the latest version
for branch in $branches; do
  if [[ $branch =~ ^cachyos_([0-9]+)\.([0-9]+)_([0-9]+)/main$ ]]; then
    major=${BASH_REMATCH[1]}
    minor=${BASH_REMATCH[2]}
    date=${BASH_REMATCH[3]}
    if (( major > latest_major )) || (( major == latest_major && minor > latest_minor )) || (( major == latest_major && minor == latest_minor && date > latest_date )); then
      latest_major=$major
      latest_minor=$minor
      latest_date=$date
      latest_branch=$branch
    fi
  fi
done

npins add github --frozen -b "$latest_branch" "$REPO_OWNER" "$REPO_NAME"
