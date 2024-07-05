#!/usr/bin/env -S nix shell nixpkgs#jq nixpkgs#gnugrep nixpkgs#gnused -c bash

set -euo pipefail

info="pkgs/faf-client/info.json"

dry_run=
force=
verbose=
while test $# != 0
do
    case "$1" in
    -d|--dry-run) dry_run=1 ;;
    -f|--force) force=1 ;;
    -v|--verbose) verbose=1 ;;
    esac
    shift
done

if [ -n "$verbose" ]; then
    echo "Printing verbose info (force: ${force+1}, dry: ${dry_run+1})"
fi

system=$(nix-instantiate --eval -E 'builtins.currentSystem' | tr -d '"')

if [ -n "$verbose" ]; then
    echo "Current system: $system"
fi

oldVersionStable=$(jq -r '.versionStable' "$info")
oldVersionUnstable=$(jq -r '.versionUnstable' "$info")
oldVersionIce=$(jq -r '.versionIce' "$info")

if [ -n "$verbose" ]; then
    echo "Old versions: $oldVersionIce $oldVersionStable $oldVersionUnstable"
fi

versionStable=$(jq -r '.pins."downlords-faf-client".version' npins/sources.json | sed s/v//)
versionUnstable=$(jq -r '.pins."downlords-faf-client-unstable".version' npins/sources.json | sed s/v//)
versionIce=$(jq -r '.pins."faf-ice-adapter".version' npins/sources.json | sed s/v//)

if [ -n "$verbose" ]; then
    echo "New versions: $versionIce $versionStable $versionUnstable"
fi

if [ -n "$force" ] || [ "$oldVersionIce" != "$versionIce" ]; then
    if [ -z "$dry_run" ]; then
        if [ -n "$verbose" ]; then
            echo "\$(nix-build --no-out-link -A packages.$system.faf-client.ice-adapter.mitmCache.updateScript)"
        fi
        eval "$(nix-build --no-out-link -A "packages.$system.faf-client.ice-adapter.mitmCache.updateScript")"
        echo "{\"versionStable\":\"$oldVersionStable\",\"versionUnstable\":\"$oldVersionUnstable\",\"versionIce\":\"$versionIce\"}" > $info
        echo "Updated ice from $oldVersionIce to $versionIce"
    else
        echo "Will update ice from $oldVersionIce to $versionIce"
    fi
else
    echo "ICE adapter version is up to date: $versionIce"
fi

if [ -n "$force" ] || [ "$oldVersionStable" != "$versionStable" ]; then
    if [ -z "$dry_run" ]; then
        if [ -n "$verbose" ]; then
            echo "nix-build --no-out-link -A packages.$system.faf-client.mitmCache.updateScript"
        fi
        eval "$(nix-build --no-out-link -A "packages.$system.faf-client.mitmCache.updateScript")"
        echo "{\"versionStable\":\"$versionStable\",\"versionUnstable\":\"$oldVersionUnstable\",\"versionIce\":\"$versionIce\"}" > $info
        echo "Updated stable from $oldVersionStable to $versionStable"
    else
        echo "Will update stable from $oldVersionStable to $versionStable"
    fi
else
    echo "Stable version is up to date: $versionStable"
fi

if [ -n "$force" ] || [ "$oldVersionUnstable" != "$versionUnstable" ]; then
    if [ -z "$dry_run" ]; then
        if [ -n "$verbose" ]; then
            echo "nix-build --no-out-link -A packages.$system.faf-client-unstable.mitmCache.updateScript"
        fi
        eval "$(nix-build --no-out-link -A "packages.$system.faf-client-unstable.mitmCache.updateScript")"
        echo "{\"versionStable\":\"$versionStable\",\"versionUnstable\":\"$versionUnstable\",\"versionIce\":\"$versionIce\"}" > $info
        echo "Updated unstable from $oldVersionUnstable to $versionUnstable"
    else
        echo "Will update unstable from $oldVersionUnstable to $versionUnstable"
    fi
else
    echo "Unstable version is up to date: $versionUnstable"
fi

echo "done!"

