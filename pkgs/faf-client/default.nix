{
  lib,
  pins,
  stdenvNoCC,
  makeDesktopItem,
  openjdk21,
  gradle,
  perl,
  substituteAll,
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
  deps ? null,
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
  deps' = deps;
in let
  pname = "faf-client";

  version = builtins.replaceStrings ["v"] [""] src.version;

  src =
    if unstable
    then pins.downlords-faf-client-unstable
    else pins.downlords-faf-client;

  meta = with lib; {
    description = "Official client for Forged Alliance Forever";
    homepage = "https://github.com/FAForever/downlords-faf-client";
    license = licenses.mit;
    maintainers = with maintainers; [chayleaf];
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

  libs = [
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

  depsHashStable = "sha256:8mpLf5jqOzGb/afThJJ+TLM7bW5ahvKAuuL2W+PSK60=";
  depsHashUnstable = "sha256:8mpLf5jqOzGb/afThJJ+TLM7bW5ahvKAuuL2W+PSK60=";

  deps =
    if deps' != null
    then deps'
    else
      stdenvNoCC.mkDerivation {
        pname = "${pname}-deps";
        java_home = openjdk21;
        inherit src version;
        init_deps = ./init-deps.gradle;
        buildscript_gradle_lockfile =
          if unstable
          then ./buildscript-gradle-unstable.lockfile
          else ./buildscript-gradle-stable.lockfile;
        gradle_lockfile =
          if unstable
          then ./gradle-unstable.lockfile
          else ./gradle-stable.lockfile;
        postPatch = ''
          cp $gradle_lockfile gradle.lockfile
          cp $buildscript_gradle_lockfile buildscript-gradle.lockfile
        '';
        nativeBuildInputs = [gradle perl];
        preBuild = ''
          export GRADLE_USER_HOME=$(mktemp -d)
          export TERM=dumb
          sed -i "s/-SNAPSHOT/latest.integration/g" build.gradle
        '';
        buildPhase = ''
          runHook preBuild
          gradle --info --no-daemon --init-script $init_deps -Dorg.gradle.java.home=$java_home -PjavafxPlatform=${jfxPlatform} downloadDependencies
          runHook postBuild
        '';
        installPhase = ''
          find $GRADLE_USER_HOME/caches/modules-2 -type f -regex '.*\.\(jar\|pom\)' \
            | perl -pe 's#(.*/([^/]+)/([^/]+)/([^/]+)/[0-9a-f]{30,40}/([^/\s]+))$# ($x = $2) =~ tr|\.|/|; "install -Dm444 $1 \$out/$x/$3/$4/$5" #e' \
            | sort \
            | sh
          cp gradle.lockfile buildscript-gradle.lockfile $out
          ${
            # HACK: allow using deprecated package names
            builtins.concatStringsSep "\n" (lib.flip lib.mapAttrsToList {
                "com/squareup/okio/okio" = "com/squareup/okio/okio-jvm";
                "org/jetbrains/kotlin/kotlin-stdlib-common" = "org/jetbrains/kotlin/kotlin-stdlib";
              } (alias: real: let
                aliasName = lib.last (lib.splitString "/" alias);
                realName = lib.last (lib.splitString "/" real);
              in ''
                for ver in $(ls "$out/${alias}" || true); do
                  ln -s "$out/${real}/$ver/${realName}-$ver.jar" "$out/${alias}/$ver/${aliasName}-$ver.jar" || true
                done
              ''))
          }
        '';
        outputHashMode = "recursive";
        outputHash =
          if unstable
          then depsHashUnstable
          else depsHashStable;
        passthru.updateLockfile = deps.overrideAttrs (old: {
          gradle_lockfile = "";
          buildscript_gradle_lockfile = "";
          postPatch = "";
          # sadly, we have to do it twice to make sure the hashes match
          # (we have to download more pom files than we will need at build time before we can generate the lockfile)
          buildPhase = ''
            runHook preBuild
            gradle --write-locks --no-daemon --init-script $init_deps -Dorg.gradle.java.home=$java_home -PjavafxPlatform=${jfxPlatform} downloadDependencies
            rm -rf $GRADLE_USER_HOME
            export GRADLE_USER_HOME=$(mktemp -d)
            gradle --no-daemon --init-script $init_deps -Dorg.gradle.java.home=$java_home -PjavafxPlatform=${jfxPlatform} downloadDependencies
            runHook postBuild
          '';
        });
      };
  gradleInit = substituteAll {
    src = ./init.gradle;
    inherit deps;
  };
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
in
  stdenvNoCC.mkDerivation {
    inherit pname version meta src desktopItem gawk runtimeShell;
    java_home = openjdk21;
    libs = lib.makeLibraryPath libs;

    postPatch = ''
      cp ${deps}/gradle.lockfile ${deps}/buildscript-gradle.lockfile ./
      chmod +w gradle.lockfile buildscript-gradle.lockfile
      sed -i "s/-SNAPSHOT/latest.integration/g" build.gradle
      sed -i 's/dependencies {/dependencies{modules{module("com.google.guava:listenablefuture"){replacedBy("com.google.guava:guava","listenablefuture is part of guava")}}/g' build.gradle
    '';

    patches = lib.optionals (!enableUpdateCheck) [./disable-update-check.patch];

    nativeBuildInputs = [
      gradle
    ];

    buildPhase = ''
      runHook preBuild
      export GRADLE_USER_HOME=$(mktemp -d)
      sed -i "s#downloadWindowsUid, ##" build.gradle
      sed -i "s#downloadWindowsUid.outputs.files##" build.gradle
      mkdir -p build/resources/native
      cp ${uid}/bin/faf-uid build/resources/native/
      cp ${ice-adapter} build/resources/native/faf-ice-adapter.jar
      gradle --offline --no-daemon \
        -Dorg.gradle.java.home=$java_home \
        -Pversion=$version \
        -PjavafxPlatform=${jfxPlatform} \
        --init-script ${gradleInit} \
        installDist
      runHook postBuild
    '';

    # tests are somewhat unstable so they're disabled by default
    # nonetheless, they are helpful to see if something is very wrong
    doCheck = false;
    checkPhase = ''
      LD_LIBRARY_PATH=${lib.makeLibraryPath libs} gradle --offline --no-daemon \
        -Dorg.gradle.java.home=$java_home \
        -Pversion=$version \
        -PjavafxPlatform=${jfxPlatform} \
        test
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out/bin $out/lib/faf-client/lib $out/lib/faf-client/natives $out/share
      cp build/install/faf-client/* $out/lib/faf-client/lib

      mv $out/lib/faf-client/lib/faf-uid $out/lib/faf-client/lib/faf-ice-adapter.jar $out/lib/faf-client/natives
      ln -s ../natives/faf-uid $out/lib/faf-client/lib/faf-uid
      ln -s ../natives/faf-ice-adapter.jar $out/lib/faf-client/lib/faf-ice-adapter.jar

      cp -r $desktopItem/share/* $out/share/
      pushd src/media/appicon
      for icon in *.png; do
        dir=$out/share/icons/hicolor/"''${icon%.png}x''${icon%.png}"/apps
        mkdir -p "$dir"
        cp "$icon" "$dir"/${icon}.png
      done
      popd

      cp build/resources/main/steam_appid.txt $out/lib/faf-client

      substituteAll ${./start.sh} $out/bin/faf-client
      chmod +x $out/bin/faf-client
      cp ${./faf-client-setup.py} $out/bin/faf-client-setup
      chmod +x $out/bin/faf-client-setup

      runHook postInstall
    '';

    passthru = {
      inherit deps uid ice-adapter;
      updateScript = ./update-src.sh;
    };
  }
