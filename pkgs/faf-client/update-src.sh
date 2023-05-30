#!/usr/bin/env -S nix shell nixpkgs#jq nixpkgs#gnugrep nixpkgs#gnused -c bash

set -euo pipefail

filePath="pkgs/faf-client/default.nix"
filePathIce="pkgs/faf-client/ice-adapter.nix"

lockfileStable="pkgs/faf-client/gradle-stable.lockfile"
lockfileUnstable="pkgs/faf-client/gradle-unstable.lockfile"
lockfileIce="pkgs/faf-client/gradle-ice.lockfile"

blockfileStable="pkgs/faf-client/buildscript-gradle-stable.lockfile"
blockfileUnstable="pkgs/faf-client/buildscript-gradle-unstable.lockfile"
blockfileIce="pkgs/faf-client/buildscript-gradle-ice.lockfile"

info="pkgs/faf-client/info.json"

dry_run=
verbose=
while test $# != 0
do
    case "$1" in
    -d|--dry-run) dry_run=1 ;;
    -v|--verbose) verbose=1 ;;
    esac
    shift
done

if [ -n "$verbose" ]; then
    echo "Printing verbose info"
fi

# get string variable contents from the nix file
function getValue()
{
    grep "$1 = " $filePath | sed 's/.*= "//g' | sed 's/".*//g'
}
function getValueIce()
{
    grep "$1 = " $filePathIce | sed 's/.*= "//g' | sed 's/".*//g'
}
function calcHash()
{
    echo -n sha256:
    (nix-build --no-out-link -A "$1" || true) |& grep --perl-regexp --only-matching 'got: +.+[:-]\K.+'
}
function outPath()
{
    nix build --accept-flake-config ".#$1" --print-out-paths
}
function replaceInFile()
{
    if [ -n "$dry_run" ]; then
        echo "will replace "'`'"$1"'`'" with "'`'"$2"'`'
    else
        if [ -n "$verbose" ]; then
            echo "replacing "'`'"$1"'`'" with "'`'"$2"'`'
        fi
        sed -i "s%$1%$2%g" "$filePath"
        if [ -n "$verbose" ]; then
            echo "replaced"
        fi
    fi
}
function replaceInIce()
{
    if [ -n "$dry_run" ]; then
        echo "will replace "'`'"$1"'`'" with "'`'"$2"'` in ice'
    else
        if [ -n "$verbose" ]; then
            echo "replacing "'`'"$1"'`'" with "'`'"$2"'` in ice'
        fi
        sed -i "s%$1%$2%g" "$filePathIce"
        if [ -n "$verbose" ]; then
            echo "replaced"
        fi
    fi
}

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

fakeHash_1="sha256:0000000000000000000000000000000000000000000000000000000000000001"
fakeHash_2="sha256:0000000000000000000000000000000000000000000000000000000000000002"

if [ -n "$verbose" ]; then
    echo "New versions: $versionIce $versionStable $versionUnstable"
fi

if [ "$oldVersionIce" != "$versionIce" ]; then
    oldHashIce=$(getValueIce outputHash)
    replaceInIce "outputHash = \"$oldHashIce" "outputHash = \"$fakeHash_1"

    if [ -z "$dry_run" ]; then
        if [ -n "$verbose" ]; then
            echo "nix-build --no-out-link -A packages.$system.faf-client.ice-adapter.deps.updateLockfile"
        fi
        hashIce=$(calcHash "packages.$system.faf-client.ice-adapter.deps.updateLockfile")
        replaceInIce "$fakeHash_1" "$hashIce"
        rm -f $lockfileIce $blockfileIce
        if [ -n "$verbose" ]; then
            echo "copying $(outPath "packages.$system.faf-client.ice-adapter.deps.updateLockfile")/gradle.lockfile"
            echo "copying $(outPath "packages.$system.faf-client.ice-adapter.deps.updateLockfile")/buildscript-gradle.lockfile"
        fi
        cp "$(outPath "packages.$system.faf-client.ice-adapter.deps.updateLockfile")/gradle.lockfile" $lockfileIce
        cp "$(outPath "packages.$system.faf-client.ice-adapter.deps.updateLockfile")/buildscript-gradle.lockfile" $blockfileIce
        echo "{\"versionStable\":\"$oldVersionStable\",\"versionUnstable\":\"$oldVersionUnstable\",\"versionIce\":\"$versionIce\"}" > $info
        echo "Updated ice from $oldVersionIce to $versionIce"
    else
        echo "Will update ice from $oldVersionIce to $versionIce"
    fi
else
    echo "ICE adapter version is up to date: $versionIce"
fi

if [ "$oldVersionStable" != "$versionStable" ]; then
    oldHashStable=$(getValue depsHashStable)
    replaceInFile "depsHashStable = \"$oldHashStable" "depsHashStable = \"$fakeHash_1"

    if [ -z "$dry_run" ]; then
        if [ -n "$verbose" ]; then
            echo "nix-build --no-out-link -A packages.$system.faf-client.deps.updateLockfile"
        fi
        hashStable=$(calcHash "packages.$system.faf-client.deps.updateLockfile")
        replaceInFile "$fakeHash_1" "$hashStable"
        rm -f $lockfileStable $blockfileStable
        if [ -n "$verbose" ]; then
            echo "copying $(outPath "packages.$system.faf-client.deps.updateLockfile")/gradle.lockfile"
            echo "copying $(outPath "packages.$system.faf-client.deps.updateLockfile")/buildscript-gradle.lockfile"
        fi
        cp "$(outPath "packages.$system.faf-client.deps.updateLockfile")/gradle.lockfile" $lockfileStable
        cp "$(outPath "packages.$system.faf-client.deps.updateLockfile")/buildscript-gradle.lockfile" $blockfileStable
        echo "{\"versionStable\":\"$versionStable\",\"versionUnstable\":\"$oldVersionUnstable\",\"versionIce\":\"$versionIce\"}" > $info
        echo "Updated stable from $oldVersionStable to $versionStable"
    else
        echo "Will update stable from $oldVersionStable to $versionStable"
    fi
else
    echo "Stable version is up to date: $versionStable"
fi

if [ "$oldVersionUnstable" != "$versionUnstable" ]; then
    oldHashUnstable=$(getValue depsHashUnstable)
    replaceInFile "depsHashUnstable = \"$oldHashUnstable" "depsHashUnstable = \"$fakeHash_2"

    if [ -z "$dry_run" ]; then
        if [ -n "$verbose" ]; then
            echo "nix-build --no-out-link -A packages.$system.faf-client-unstable.deps.updateLockfile"
        fi
        hashUnstable=$(calcHash "packages.$system.faf-client-unstable.deps.updateLockfile")
        replaceInFile "$fakeHash_2" "$hashUnstable"
        rm -f $lockfileUnstable $blockfileUnstable
        if [ -n "$verbose" ]; then
            echo "copying $(outPath "packages.$system.faf-client-unstable.deps.updateLockfile")/gradle.lockfile"
            echo "copying $(outPath "packages.$system.faf-client-unstable.deps.updateLockfile")/buildscript-gradle.lockfile"
        fi
        cp "$(outPath "packages.$system.faf-client-unstable.deps.updateLockfile")/gradle.lockfile" $lockfileUnstable
        cp "$(outPath "packages.$system.faf-client-unstable.deps.updateLockfile")/buildscript-gradle.lockfile" $blockfileUnstable
        echo "{\"versionStable\":\"$versionStable\",\"versionUnstable\":\"$versionUnstable\",\"versionIce\":\"$versionIce\"}" > $info
        echo "Updated unstable from $oldVersionUnstable to $versionUnstable"
    else
        echo "Will update unstable from $oldVersionUnstable to $versionUnstable"
    fi
else
    echo "Unstable version is up to date: $versionUnstable"
fi

echo "done!"

