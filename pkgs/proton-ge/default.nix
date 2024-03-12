{
  stdenvNoCC,
  lib,
  fetchurl,
  nix-update-script,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "proton-ge-custom";
  version = "GE-Proton9-1";

  src = fetchurl {
    url = "https://github.com/GloriousEggroll/proton-ge-custom/releases/download/${finalAttrs.version}/${finalAttrs.version}.tar.gz";
    hash = "sha512-e1f7ae1e2ead74aa23657e421410c1e69d986d9ece4877aba9e90901d0b17c717d99616dd44f1458fa3c4faee6ca5078a5e5f2d5b1e3308a81888717b978b154";
  };

  buildCommand = ''
    runHook preBuild
    mkdir -p $out/bin
    tar -C $out/bin --strip=1 -x -f $src
    runHook postBuild
  '';

  passthru.updateScript = nix-update-script {};

  meta = {
    description = "Compatibility tool for Steam Play based on Wine and additional components";
    homepage = "https://github.com/GloriousEggroll/proton-ge-custom";
    license = lib.licenses.bsd3;
    maintainers = with lib.maintainers; [NotAShelf];
    platforms = ["x86_64-linux"];
  };
})
