{
  stdenvNoCC,
  bash,
  fetchurl,
  ...
}: let
  version = "0.1";
in
  stdenvNoCC.mkDerivation {
    name = "powerstub";
    inherit version;

    src = fetchurl {
      url = "https://github.com/ngh246/powerstub/releases/download/v${version}/powerstub-v${version}.tar.gz";
      hash = "sha256-l7SgYXoqIhL/GmbFgf8GfQJUMaaJ2QK5Qo8pYf2ydac=";
    };

    installPhase = ''
      mkdir -p $out/bin $out/lib
      substitute install.sh $out/bin/install.sh \
        --subst-var-by bash ${bash}
      substituteInPlace $out/bin/install.sh \
        --replace-fail 'CURDIR=$(pwd)' CURDIR=$out/lib
      chmod a+x $out/bin/install.sh
      cp -rv x86 $out/lib/
      cp -rv x86_64 $out/lib/
    '';
  }
