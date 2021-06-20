{ pkgsCross, stdenv, dib }:

stdenv.mkDerivation {
  pname = "discord-ipc-bridge";
  version = "unstable-2020-12-12";

  src = dib;

  buildPhase = "$CC -masm=intel -mconsole main.c -o winediscordipcbridge.exe";
  installPhase = "mkdir -p $out/bin; cp winediscordipcbridge.exe $out/bin";
}
