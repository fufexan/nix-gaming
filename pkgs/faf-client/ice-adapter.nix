{
  lib,
  pins,
  stdenvNoCC,
  gradle,
  enableJfx ? true,
}: let
  pname = "faf-ice-adapter";

  src = pins.faf-ice-adapter;
  version = builtins.replaceStrings ["v"] [""] src.version;

  jfxPlatform =
    if stdenvNoCC.isDarwin
    then
      (
        if stdenvNoCC.isAarch64
        then "mac-aarch64"
        else if stdenvNoCC.isx86_64
        then "mac"
        else null
      )
    else if stdenvNoCC.isLinux
    then
      (
        if stdenvNoCC.isAarch64
        then "linux-aarch64"
        else if stdenvNoCC.isx86_64
        then "linux"
        else null
      )
    else null;

  self = stdenvNoCC.mkDerivation rec {
    inherit pname version src;
    name = "${pname}-${version}.jar";

    nativeBuildInputs = [gradle];

    gradleFlags =
      ["-Pversion=${version}" "-PjavafxPlatform=${jfxPlatform}"]
      ++ lib.optional (!enableJfx) "-PjavafxClasspath=compileOnly";

    gradleBuildTask = ":ice-adapter:shadowJar";

    installPhase = ''
      cp ice-adapter/build/libs/faf-ice-adapter-${version}-${
        if enableJfx
        then "linux"
        else "nojfx"
      }.jar $out
    '';

    mitmCache = gradle.fetchDeps {
      inherit pname;
      data = ./deps-ice.json;
      pkg = self;
    };
    __darwinAllowLocalNetworking = true;

    gradleUpdateScript = ''
      runHook preBuild
      for jfxPlatform in {mac,linux}{,-aarch64}; do
        gradleFlags="-Pversion=${version} -PjavafxPlatform=$jfxPlatform"
        gradle nixDownloadDeps
        gradleFlags="-Pversion=${version} -PjavafxPlatform=$jfxPlatform -PjavafxClasspath=compileOnly"
        gradle nixDownloadDeps
      done
    '';

    meta = with lib; {
      description = "A P2P connection proxy for Supreme Commander: Forged Alliance using ICE";
      homepage = "https://github.com/FAForever/java-ice-adapter";
      license = with licenses; [mit];
      maintainers = with maintainers; [chayleaf];
    };
  };
in
  self
