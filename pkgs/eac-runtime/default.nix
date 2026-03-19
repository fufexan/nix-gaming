{
  fetchzip,
  stdenvNoCC,
  autoPatchelfHook,
}:
stdenvNoCC.mkDerivation {
  pname = "eac-runtime";
  version = "20240114";

  src = fetchzip {
    url = "https://github.com/lutris/buildbot/releases/download/2022.06.23/eac_runtime-20240114.tar.xz";
    sha256 = "sha256-e8QzC7pxx890j4jIdtqai+ugq4JmvCgJ171phXyZcxo=";
  };

  installPhase = "cp -r ./ $out";

  nativeBuildInputs = [ autoPatchelfHook ];

  autoPatchelfIgnoreMissingDeps = [ "*" ];
}
