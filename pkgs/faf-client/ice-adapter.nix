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
        gradle_lockfile = ./gradle-ice.lockfile;
        postPatch = ''
          cp $gradle_lockfile ice-adapter/gradle.lockfile
        '';
        nativeBuildInputs = [gradle perl];
        preBuild = ''
          export GRADLE_USER_HOME=$(mktemp -d)
          sed -i "s/-SNAPSHOT/latest.integration/g" ice-adapter/build.gradle
          sed -i "s/mavenLocal()//g" ice-adapter/build.gradle
          cat <<END >> ice-adapter/build.gradle
          dependencyLocking {
            lockAllConfigurations()
          }
          task downloadDependencies {
            doLast {
              configurations.findAll{it.canBeResolved}.each{it.resolve()}
              buildscript.configurations.findAll{it.canBeResolved}.each{it.resolve()}
            }
          }
          END
        '';
        buildPhase = ''
          runHook preBuild
          gradle --no-daemon -PjavafxPlatform=${jfxPlatform} ${
            if enableJfx
            then ""
            else "-PjavafxClasspath=compileOnly"
          } :ice-adapter:downloadDependencies
          runHook postBuild
        '';
        installPhase = ''
          find $GRADLE_USER_HOME/caches/modules-2 -type f -regex '.*\.\(jar\|pom\)' \
            | perl -pe 's#(.*/([^/]+)/([^/]+)/([^/]+)/[0-9a-f]{30,40}/([^/\s]+))$# ($x = $2) =~ tr|\.|/|; "install -Dm444 $1 \$out/$x/$3/$4/$5" #e' \
            | sh
          cp ice-adapter/gradle.lockfile $out
        '';
        # couldn't figure out how to disable fixup...
        postFixup = ''
          mv $out/share/info $out/info
          rmdir $out/share
        '';
        outputHashMode = "recursive";
        outputHash = "sha256-UTlbZYRxoJWZyVt0zRkaQPD9d2UkKfbYmTqCCBy77Wg=";
        passthru.updateLockfile = deps.overrideAttrs (old: {
          gradle_lockfile = "";
          postPatch = "";
          # sadly, we have to do it twice to make sure the hashes match
          # (we have to download more pom files than we will need at build time before we can generate the lockfile)
          buildPhase = ''
            runHook preBuild
            gradle --write-locks --no-daemon -PjavafxPlatform=${jfxPlatform} ${
              if enableJfx
              then ""
              else "-PjavafxClasspath=compileOnly"
            } :ice-adapter:downloadDependencies
            rm -rf $GRADLE_USER_HOME
            export GRADLE_USER_HOME=$(mktemp -d)
            gradle --no-daemon -PjavafxPlatform=${jfxPlatform} ${
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
      cp ${deps}/gradle.lockfile ice-adapter/gradle.lockfile
      chmod +w ice-adapter/gradle.lockfile
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
