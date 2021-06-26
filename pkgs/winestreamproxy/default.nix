{ stdenv
, lib
, fetchFromGitHub
, pkg-config
, wine
}:

stdenv.mkDerivation rec {
  pname = "winestreamproxy";
  version = "unstable-2020-10-17";

  src = fetchFromGitHub {
    owner = "openglfreak";
    repo = pname;
    rev = "075622872bbff0621791296137edb616af680297";
    sha256 = "sha256-I579RJ9iBREYnqEiEgFXWbPSatbVv0cjMHloK2l5D6Q=";
  };

  nativeBuildInputs = [ pkg-config wine ];

  installFlags = [ "PREFIX=${placeholder "out"}" ];

  meta = {
    description = "Program for Wine that forwards messages between a named pipe client and a unix socket server";
    homepage = "https://github.com/openglfreak/winestreamproxy";
    maintainers = with lib.maintainers; [ fufexan ];
    platforms = with lib.platforms; [ "i686-linux" "x86_64-linux" ];
  };
}
