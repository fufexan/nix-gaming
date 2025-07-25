rec {
  base = {
    gettextSupport = true;
    fontconfigSupport = true;
    alsaSupport = true;
    openglSupport = true;
    vulkanSupport = true;
    tlsSupport = true;
    cupsSupport = true;
    dbusSupport = true;
    cairoSupport = true;
    cursesSupport = true;
    saneSupport = true;
    pulseaudioSupport = true;
    udevSupport = true;
    xineramaSupport = true;
    sdlSupport = true;
    mingwSupport = true;
    usbSupport = true;
    waylandSupport = false; # disabled for wine-osu (Wine 7.0 doesn't support Wayland)
    x11Support = true;
    gtkSupport = false;
    gstreamerSupport = false;
    openclSupport = false;
    odbcSupport = false;
    netapiSupport = false;
    vaSupport = false;
    pcapSupport = false;
    v4lSupport = false;
    gphoto2Support = false;
    krb5Support = false;
    embedInstallers = false;
  };

  full =
    base
    // {
      gtkSupport = true;
      gstreamerSupport = true;
      openclSupport = true;
      odbcSupport = true;
      netapiSupport = true;
      vaSupport = true;
      pcapSupport = true;
      v4lSupport = true;
      gphoto2Support = true;
      krb5Support = true;
      embedInstallers = true;
      waylandSupport = true; # re-enabled for newer Wine versions that support Wayland
    };
}
