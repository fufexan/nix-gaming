{
  lib,
  pins,
  stdenvNoCC,
  makeDesktopItem,
  openjdk21,
  openjdk25,
  gradle_8,
  gradle_9,
  runtimeShell,
  gawk,
  # can't we somehow patchelf the openjfx runtime during build phase?
  alsa-lib,
  libGL,
  glib,
  gtk3,
  xorg,
  fontconfig,
  freetype,
  pango,
  callPackage,
  uid ? callPackage ./uid.nix {inherit pins;},
  ice-adapter ?
    callPackage ./ice-adapter.nix {
      inherit pins;
      enableJfx = false;
    },
  unstable ? false,
  enablePatches ? true,
  enableUpdateCheck ? (!enablePatches),
}: let
  pname = "faf-client";

  jdk =
    if lib.versionAtLeast version "2025.9.3"
    then openjdk25
    else openjdk21;

  gradle =
    if lib.versionAtLeast version "2025.9.3"
    then gradle_9
    else gradle_8;

  version = builtins.replaceStrings ["v"] [""] src.version;

  src =
    if unstable
    then pins.downlords-faf-client-unstable
    else pins.downlords-faf-client;

  depsPath =
    if unstable
    then ./deps-unstable.json
    else ./deps-stable.json;

  meta = with lib; {
    description = "Official client for Forged Alliance Forever";
    homepage = "https://github.com/FAForever/downlords-faf-client";
    license = licenses.mit;
    maintainers = with maintainers; [chayleaf];
    platforms = platforms.darwin ++ ["x86_64-linux"];
  };

  icon = "faf-client";

  desktopItem = makeDesktopItem {
    inherit icon;
    name = "faf-client";
    exec = "faf-client";
    comment = meta.description;
    desktopName = "Forged Alliance Forever";
    categories = ["Game"];
    keywords = ["FAF" "Supreme Commander"];
  };

  libs = lib.optionals stdenvNoCC.isLinux [
    alsa-lib
    fontconfig
    freetype
    glib
    gtk3
    libGL
    pango
    xorg.libX11
    xorg.libXtst
    xorg.libXxf86vm
  ];

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
    then "linux"
    else null;

  self = stdenvNoCC.mkDerivation {
    inherit pname version meta src desktopItem gawk runtimeShell;
    libs = lib.makeLibraryPath libs;

    patches = lib.optionals (!enableUpdateCheck) [./disable-update-check.patch];

    nativeBuildInputs = [
      gradle
    ];

    postPatch = ''
      sed -i '/.*\.outputs\.files,\?/d' build.gradle
      sed -i "s#compileJava\\.dependsOn 'downloadNativeDependencies'##" build.gradle
      sed -i "s#codacy-coverage-reporter:-SNAPSHOT#codacy-coverage-reporter:latest.integration#" build.gradle
    '';
    gradleFlags = ["-Dorg.gradle.java.home=${jdk}" "-Pversion=${version}" "-PjavafxPlatform=${jfxPlatform}"];

    preBuild = ''
      mkdir -p build/resources/native
      cp ${uid}/bin/faf-uid build/resources/native/
      cp ${ice-adapter} build/resources/native/faf-ice-adapter.jar
    '';

    gradleBuildTask = "installDist";

    # tests are somewhat unstable so they're disabled by default
    # nonetheless, they are helpful to see if something is very wrong
    doCheck = false;

    preCheck = ''
      export LD_LIBRARY_PATH=${lib.makeLibraryPath libs}
    '';

    java_home = jdk;

    installPhase = ''
      runHook preInstall

      mkdir -p $out/bin $out/lib/faf-client/lib $out/lib/faf-client/natives $out/share
      cp build/install/faf-client/* $out/lib/faf-client/lib

      ln -s ${uid}/bin/faf-uid $out/lib/faf-client/natives/faf-uid
      ln -s ${uid}/bin/faf-uid $out/lib/faf-client/lib/faf-uid
      ln -s ${ice-adapter} $out/lib/faf-client/natives/faf-ice-adapter.jar
      ln -s ${ice-adapter} $out/lib/faf-client/lib/faf-ice-adapter.jar

      cp -r $desktopItem/share/* $out/share/
      pushd src/media/appicon
      for icon in *.png; do
        dir=$out/share/icons/hicolor/"''${icon%.png}x''${icon%.png}"/apps
        mkdir -p "$dir"
        cp "$icon" "$dir"/${icon}.png
      done
      popd

      cp build/resources/main/steam_appid.txt $out/lib/faf-client/

      substituteAll ${./start.sh} $out/bin/faf-client
      chmod +x $out/bin/faf-client
      cp ${./faf-client-setup.py} $out/bin/faf-client-setup
      chmod +x $out/bin/faf-client-setup

      runHook postInstall
    '';

    mitmCache = gradle.fetchDeps {
      inherit pname;
      data = depsPath;
      pkg = self;
      useBwrap = false;
    };
    __darwinAllowLocalNetworking = true;

    gradleUpdateScript = ''
      runHook preBuild
      for jfxPlatform in {mac,mac-aarch64,linux}; do
        gradleFlags="-Dorg.gradle.java.home=${jdk} -Pversion=${version} -PjavafxPlatform=$jfxPlatform"
        gradle nixDownloadDeps
        gradleFlags="-Dorg.gradle.java.home=${jdk} -Pversion=${version} -PjavafxPlatform=$jfxPlatform -PjavafxClasspath=compileOnly"
        gradle nixDownloadDeps
      done
    '';

    passthru = {
      inherit uid ice-adapter;
      updateScript = ./update-src.sh;
    };
  };
in
  self
