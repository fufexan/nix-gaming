{ wineUnstable, ... }:

(
  wineUnstable.overrideAttrs (
    old: {
      patches = old.patches ++ [
        # fixes latency on pulse backend
        ./wine-pulse.patch
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
