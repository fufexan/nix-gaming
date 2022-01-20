{ inputs
, lib
, build
, pkgs
, pkgsCross
, pkgsi686Linux
, callPackage
, fetchFromGitHub
, fetchurl
, supportFlags
, stdenv_32bit
}:

let
  fetchurl = args@{ url, sha256, ... }:
    pkgs.fetchurl { inherit url sha256; } // args;

  gecko32 = fetchurl rec {
    version = "2.47.2";
    url = "https://dl.winehq.org/wine/wine-gecko/${version}/wine-gecko-${version}-x86.msi";
    sha256 = "07d6nrk2g0614kvwdjym1wq21d2bwy3pscwikk80qhnd6rrww875";
  };
  gecko64 = fetchurl rec {
    version = "2.47.2";
    url = "https://dl.winehq.org/wine/wine-gecko/${version}/wine-gecko-${version}-x86_64.msi";
    sha256 = "0iffhvdawc499nbn4k99k33cr7g8sdfcvq8k3z1g6gw24h87d5h5";
  };
  mono = fetchurl rec {
    version = "5.1.1";
    url = "https://dl.winehq.org/wine/wine-mono/${version}/wine-mono-${version}-x86.msi";
    sha256 = "09wjrfxbw0072iv6d2vqnkc3y7dzj15vp8mv4ay44n1qp5ji4m3l";
  };

  defaults = with pkgs; {
    inherit supportFlags;
    patches = [ ];
    buildScript = "${inputs.nixpkgs}/pkgs/misc/emulators/wine/builder-wow.sh";
    geckos = [ gecko32 gecko64 ];
    mingwGccs = with pkgsCross; [ mingw32.buildPackages.gcc mingwW64.buildPackages.gcc ];
    monos = [ mono ];
    pkgArches = [ pkgs pkgsi686Linux ];
    platforms = [ "x86_64-linux" ];
    stdenv = stdenv_32bit;
  };

  pnameGen = n: n + lib.optionalString (build == "full") "-full";
in
{
  wine-tkg =
    let
      pname = pnameGen "wine-tkg";
    in
    callPackage "${inputs.nixpkgs}/pkgs/misc/emulators/wine/base.nix" (defaults // rec {
      name = "${pname}-${version}";
      version = "6.22";
      src = fetchFromGitHub {
        owner = "Tk-Glitch";
        repo = "wine-tkg";
        rev = "8b6c44352c188872eb0e12372ebe77ea569b873c";
        sha256 = "sha256-8HiuNsSVfmIXv+mw+5/N8gJ0g3vpx1nfm22MynYQKFQ=";
      };
    });

  wine-osu =
    let
      pname = pnameGen "wine-osu";
    in
    callPackage "${inputs.nixpkgs}/pkgs/misc/emulators/wine/base.nix" (defaults // rec {
      name = "${pname}-${version}";
      version = "6.14";
      src = fetchFromGitHub {
        owner = "wine-mirror";
        repo = "wine";
        rev = "wine-${version}";
        sha256 = "sha256-Ij0NtLp9Vq8HBkAeMrv2x0YdiPxEYgYc6lpn5dqbtzk=";
      };
      patches = [
        "${inputs.nixpkgs}/pkgs/misc/emulators/wine/cert-path.patch"
        ./patches/0001-Revert-to-5.14-winepulse.drv.patch
        ./patches/0002-5.14-Latency-Fix.patch
        ./patches/0003-secur32-Fix-crash-from-invalid-context-in-Initialize.patch
        ./patches/0004-kernelbase-Cache-last-used-locale-sortguid-mapping.patch
        ./patches/0005-Add-ps0034-and-ps0035-from-openglfreak.patch
      ];
    });
}
