{
  pins,
  fetchurl,
  ...
}: let
  version = pins.wine-mono.version;
  # can be updated using `npins update && pkgs/wine-mono/update.sh`
  info = builtins.fromJSON (builtins.readFile ./info.json);
in
  fetchurl {
    inherit (info) version hash;
    url = "https://github.com/wine-mono/wine-mono/releases/download/${version}/${version}-x86.msi";
  }
