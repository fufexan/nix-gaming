{
  lib,
  pins,
  stdenvNoCC,
  substituteAll,
  gradle,
  perl,
  deps ? null,
  enableJfx ? true,
}: let
  deps' = deps;
in let
  pname = "faf-ice-adapter";

  src = pins.faf-ice-adapter;
  version = builtins.replaceStrings ["v"] [""] src.version;

  deps =
    if deps' != null
    then deps'
    else
      stdenvNoCC.mkDerivation {
        pname = "${pname}-deps";
        inherit version src;
        init_deps = ./init-deps.gradle;
        gradle_lockfile = ./gradle-ice.lockfile;
        buildscript_gradle_lockfile = ./buildscript-gradle-ice.lockfile;
        postPatch = ''
          cp $gradle_lockfile ice-adapter/gradle.lockfile
          cp $buildscript_gradle_lockfile ice-adapter/buildscript-gradle.lockfile
        '';
        nativeBuildInputs = [gradle perl];
        preBuild = ''
          export GRADLE_USER_HOME=$(mktemp -d)
          export TERM=dumb
          sed -i "s/-SNAPSHOT/latest.integration/g" ice-adapter/build.gradle
        '';
        buildPhase = ''
          runHook preBuild
          gradle --no-daemon --init-script $init_deps -PjavafxPlatform=${jfxPlatform} ${
            if enableJfx
            then ""
            else "-PjavafxClasspath=compileOnly"
          } :ice-adapter:downloadDependencies
          runHook postBuild
        '';
        installPhase = ''
          find $GRADLE_USER_HOME/caches/modules-2 -type f -regex '.*\.\(jar\|pom\)' \
            | perl -pe 's#(.*/([^/]+)/([^/]+)/([^/]+)/[0-9a-f]{30,40}/([^/\s]+))$# ($x = $2) =~ tr|\.|/|; "install -Dm444 $1 \$out/$x/$3/$4/$5" #e' \
            | sort \
            | sh
          cp ice-adapter/gradle.lockfile ice-adapter/buildscript-gradle.lockfile $out
        '';
        # couldn't figure out how to disable fixup...
        postFixup = ''
          mv $out/share/info $out/info
          rmdir $out/share
        '';
        outputHashMode = "recursive";
        outputHash = "sha256:Pk3FB9uM7rWYZnMiVQUhe0o9kzs9WvRtxqYC6lTlxsg=";
        passthru.updateLockfile = deps.overrideAttrs (old: {
          gradle_lockfile = "";
          buildscript_gradle_lockfile = "";
          postPatch = "";
          # sadly, we have to do it twice to make sure the hashes match
          # (we have to download more pom files than we will need at build time before we can generate the lockfile)
          buildPhase = ''
            runHook preBuild
            gradle --write-locks --no-daemon --init-script $init_deps -PjavafxPlatform=${jfxPlatform} ${
              if enableJfx
              then ""
              else "-PjavafxClasspath=compileOnly"
            } :ice-adapter:downloadDependencies
            rm -rf $GRADLE_USER_HOME
            export GRADLE_USER_HOME=$(mktemp -d)
            gradle --no-daemon --init-script $init_deps -PjavafxPlatform=${jfxPlatform} ${
              if enableJfx
              then ""
              else "-PjavafxClasspath=compileOnly"
            } :ice-adapter:downloadDependencies
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
  stdenvNoCC.mkDerivation rec {
    inherit pname version src;
    name = "${pname}-${version}.jar";

    postPatch = ''
      cp ${deps}/gradle.lockfile ${deps}/buildscript-gradle.lockfile ice-adapter/
      chmod +w ice-adapter/gradle.lockfile ice-adapter/buildscript-gradle.lockfile
      sed -i "s/-SNAPSHOT/latest.integration/g" ice-adapter/build.gradle
    '';

    nativeBuildInputs = [
      gradle
    ];

    buildPhase = ''
      runHook preBuild
      export GRADLE_USER_HOME=$(mktemp -d)
      gradle --no-daemon --offline -Pversion="${version}" -PjavafxPlatform=${jfxPlatform} ${
        if enableJfx
        then ""
        else "-PjavafxClasspath=compileOnly"
      } --init-script ${gradleInit} :ice-adapter:shadowJar
      runHook postBuild
    '';

    installPhase = ''
      cp ice-adapter/build/libs/faf-ice-adapter-${version}-${
        if enableJfx
        then "linux"
        else "nojfx"
      }.jar $out
    '';

    meta = with lib; {
      description = "A P2P connection proxy for Supreme Commander: Forged Alliance using ICE";
      homepage = "https://github.com/FAForever/java-ice-adapter";
      license = with licenses; [
        gpl3
        # pending switch to MIT: https://github.com/FAForever/java-ice-adapter/issues/37
      ];
      # maintainers = with maintainers; [ ];
    };

    passthru = {
      inherit deps;
    };
  }
