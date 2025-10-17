{
  lib,
  pins,
  stdenv,
  cmake,
  pkg-config,
  jsoncpp,
  cryptopp,
  # PATH
  makeWrapper,
  coreutils,
  pciutils,
  util-linux,
  xorg,
}: let
  path =
    [
      # uname
      coreutils
      # lspci
      pciutils
    ]
    ++ lib.optionals stdenv.isLinux [
      # lsblk
      util-linux
      # xrandr
      xorg.xrandr
    ];
in
  stdenv.mkDerivation rec {
    pname = "faf-uid";
    version = builtins.replaceStrings ["v"] [""] src.version;

    src = pins.faf-uid;

    postPatch = ''
      substituteInPlace CMakeLists.txt --replace-fail "set(CMAKE_EXE_LINKER_FLAGS" "# set(CMAKE_EXE_LINKER_FLAGS"
    '';

    nativeBuildInputs = [
      cmake
      pkg-config
      makeWrapper
    ];

    buildInputs = [
      jsoncpp
      cryptopp
    ];

    cmakeFlags = [
      "-DUID_PUBKEY_BYTES=213,83,196,9,174,84,241,136,229,121,119,222,135,45,221,46,58,222,100,114,72,212,170,29,167,183,142,250,21,14,187,102,38,79,240,251,193,157,122,53,142,168,68,245,126,222,140,206,191,137,94,232,177,1,7,115,173,155,140,106,219,16,22,233,150,11,67,228,244,8,141,42,59,178,166,248,110,25,150,45,94,130,36,227,223,113,244,51,25,93,110,212,53,229,207,58,135,49,224,147,105,214,140,134,8,22,45,61,144,141,151,57,174,220,82,14,148,253,104,140,126,228,95,77,241,24,176,194,58,3,241,176,194,155,49,98,106,85,1,89,115,188,239,75,42,211,237,153,93,144,58,180,142,188,232,71,181,243,73,232,27,43,183,27,222,66,219,234,242,111,253,27,41,120,222,185,211,245,190,157,133,139,12,72,82,26,26,238,236,31,60,45,52,131,57,182,166,51,24,104,83,32,61,250,115,197,177,135,219,163,93,77,4,88,134,217,241,69,229,136,8,243,88,14,236,94,194,144,105,74,112,69,214,128,105,59,112,204,65,218,50,168,140,66,69,217,150,232,88,67,106,8,168,66,124,255"
      "-DCRYPTOPP_LIBRARIES=${cryptopp}/lib/libcryptopp${stdenv.hostPlatform.extensions.sharedLibrary}"
      "-DCRYPTOPP_INCLUDE_DIRS=${cryptopp.dev}/include"
      "-DCMAKE_POLICY_VERSION_MINIMUM=3.5"
    ];

    installPhase = ''
      mkdir -p $out/bin
      cp faf-uid $out/bin/
      wrapProgram $out/bin/faf-uid --suffix PATH : ${lib.makeBinPath path}
    '';

    meta = with lib; {
      description = "FA Forever unique id implementation";
      homepage = "https://github.com/FAForever/uid";
      license = licenses.gpl3;
      maintainers = with maintainers; [chayleaf];
    };
  }
