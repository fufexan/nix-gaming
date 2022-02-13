{ self
, inputs
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
    configureFlags = [ "--disable-tests" ];
    geckos = [ gecko32 gecko64 ];
    mingwGccs = with pkgsCross; [ mingw32.buildPackages.gcc mingwW64.buildPackages.gcc ];
    monos = [ mono ];
    pkgArches = [ pkgs pkgsi686Linux ];
    platforms = [ "x86_64-linux" ];
    stdenv = stdenv_32bit;
    vkd3dArches = lib.optionals supportFlags.vkd3dSupport [ vkd3d vkd3d_i686 ];
  };

  pnameGen = n: n + lib.optionalString (build == "full") "-full";

  vkd3d = pkgs.callPackage "${inputs.nixpkgs}/pkgs/misc/emulators/wine/vkd3d.nix" { };
  vkd3d_i686 = pkgsi686Linux.callPackage "${inputs.nixpkgs}/pkgs/misc/emulators/wine/vkd3d.nix" { };
in
{
  wine-tkg =
    let
      pname = pnameGen "wine-tkg";
    in
    callPackage "${inputs.nixpkgs}/pkgs/misc/emulators/wine/base.nix" (defaults // rec {
      name = "${pname}-${version}";
      version = "7.0";
      src = fetchFromGitHub {
        owner = "Tk-Glitch";
        repo = "wine-tkg";
        rev = "8205d63f3e14cd0d7cedbf8edf0e17f8f1e8e3f8";
        sha256 = "sha256-ehuagZjykQEXotZHvRkYr2UMjnKvmcaWXRCmqxuELCU=";
      };
    });

  wine-osu =
    let
      pname = pnameGen "wine-osu";
      version = "7.0";
      staging = fetchFromGitHub {
        owner = "wine-staging";
        repo = "wine-staging";
        rev = "v${version}";
        sha256 = "sha256-2gBfsutKG0ok2ISnnAUhJit7H2TLPDpuP5gvfMVE44o=";
      };
    in
    (callPackage "${inputs.nixpkgs}/pkgs/misc/emulators/wine/base.nix" (defaults // rec {
      name = "${pname}-${version}";
      inherit version;
      src = fetchFromGitHub {
        owner = "wine-mirror";
        repo = "wine";
        rev = "wine-${version}";
        sha256 = "sha256-uDdjgibNGe8m1EEL7LGIkuFd1UUAFM21OgJpbfiVPJs=";
      };
      patches = [ "${inputs.nixpkgs}/pkgs/misc/emulators/wine/cert-path.patch" ] ++ self.lib.mkPatches ./patches;
    })).overrideDerivation (self: {
      prePatch = ''
        patchShebangs tools
        cp -r ${staging}/patches .
        chmod +w patches
        cd patches
        patchShebangs gitapply.sh
        ./patchinstall.sh DESTDIR="$PWD/.." --all ${lib.concatMapStringsSep " " (ps: "-W ${ps}") [ ]}
        cd ..           
      '';
    });
}
