{ wineUnstable, ... }:

(
  wineUnstable.overrideAttrs (
    old: {
      patches = old.patches ++ [
        # fixes latency on pulse backend
        ./patches/wine-pulse.patch
        # fixes game crashing sometimes in song select screen
        ./patches/wine-secur32.patch
      ];
    }
  )
).override {
  wineBuild = "wine32";
  pngSupport = true;
  gettextSupport = true;
  fontconfigSupport = true;
  openglSupport = true;
  tlsSupport = true;
  gstreamerSupport = true;
  dbusSupport = true;
  mpg123Support = true;
  cairoSupport = true;
  netapiSupport = true;
  pcapSupport = true;
  saneSupport = true;
  pulseaudioSupport = true;
  udevSupport = true;
  xmlSupport = true;
}
