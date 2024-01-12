{
  stdenv,
  lib,
  fetchurl,
  nix-update-script,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "proton-ge-custom";
  version = "GE-Proton8-27";

  src = fetchurl {
    url = "https://github.com/GloriousEggroll/proton-ge-custom/releases/download/${finalAttrs.version}/${finalAttrs.version}.tar.gz";
    hash = "sha256-5fEYhazqXcMENjp+37IcF5U81vZ9bPDkS0siUVi9mdg=";
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
