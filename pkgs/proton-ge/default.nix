{
  stdenv,
  lib,
  fetchurl,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "proton-ge-custom";
  version = "GE-Proton8-3";

  src = fetchurl {
    url = "https://github.com/GloriousEggroll/proton-ge-custom/releases/download/${finalAttrs.version}/${finalAttrs.version}.tar.gz";
    hash = "sha256-JYGwb0LhIs6B2/OHiU+mJ/dAAS+Dg+MrVksAsn6IS9g=";
  };

  buildCommand = ''
    mkdir -p $out/bin
    tar -C $out/bin --strip=1 -x -f $src
  '';

  meta = with lib; {
    description = "Compatibility tool for Steam Play based on Wine and additional components";
    homepage = "https://github.com/GloriousEggroll/proton-ge-custom";
    license = licenses.bsd3;
    maintainers = with maintainers; [notashelf];
    platforms = ["x86_64-linux"];
  };
})
