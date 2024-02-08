#!/usr/bin/env -S nix shell nixpkgs#jq -c bash

packagePath="pkgs/osu-lazer-bin"
version=$(jq -r '.pins.osu.version' npins/sources.json)
oldversion=$(jq -r '.[0].version' "$packagePath/info.json")

# Concat them to make a new url
baseUrl="https://github.com/ppy/osu/releases/download/${version}/"
#baseUrl="file:///nix/store"
declare -A filenames=(
  [aarch64darwin]="osu.app.Apple.Silicon.zip"
  [x86_64darwin]="osu.app.Intel.zip"
  [x86_64linux]="osu.AppImage"
  #[aarch64darwin]="xwnckc0a6cvw6xd99m110sr5vginysjy-osu.app.Apple.Silicon.zip"
  #[x86_64darwin]="p4rrmqnn35hsjwihpdvhjy0kxmspxmgn-osu.app.Intel.zip"
  #[x86_64linux]="svxz8clgl17k8wl40f0bblsl8nj3pbw1-osu.AppImage"
)

#if [ "$oldversion" != "$version" ]; then
  for arch in "${!filenames[@]}"; do
    arch_value=${filenames[$arch]}
    output_json="${packagePath}/${arch}-info.json"
    if output=$(nix store prefetch-file "${baseUrl}/${arch_value}" --json); then
      jq --arg version "$version" '.version = $version' <<< "$output" > $output_json
      json_array+=($output_json)
    else
      echo "osu!lazer on $arch has a non-release update"
    fi
  done

  # Merge the JSON files into a single JSON list
  jq -s '.' "${json_array[@]}" > "$packagePath/info.json"

  # Cleanup the architecture-specific JSON files
  for arch in "${!filenames[@]}"; do
    rm "${packagePath}/${arch}-info.json"
  done
  
#else
# echo "osu!lazer is up to date."
#fi
