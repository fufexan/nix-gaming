{
  stdenv,
  lib,
  fetchFromGitHub,
  pkg-config,
  wine,
  pkgsCross,
}:
stdenv.mkDerivation rec {
  pname = "winestreamproxy";
  version = "2.0.1";

  src = fetchFromGitHub {
    owner = "openglfreak";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-KaI8sXAoeNqxueJ8BTvt4qZmxUOFwBVkevV0nqHOAsQ=";
  };

  nativeBuildInputs = [
    pkgsCross.mingwW64.stdenv.cc
    pkg-config
    wine
  ];

  installFlags = [ "PREFIX=${placeholder "out"}" ];

  meta = {
    description = "Program for Wine that forwards messages between a named pipe client and a unix socket server";
    homepage = "https://github.com/openglfreak/winestreamproxy";
    maintainers = with lib.maintainers; [ fufexan ];
    platforms = [
      "i686-linux"
      "x86_64-linux"
    ];
    broken = true;
  };
}
