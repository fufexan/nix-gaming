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
    gtkSupport = false;
    gstreamerSupport = false;
    openalSupport = false;
    openclSupport = false;
    odbcSupport = false;
    netapiSupport = false;
    vaSupport = false;
    pcapSupport = false;
    v4lSupport = false;
    gphoto2Support = false;
    krb5Support = false;
    embedInstallers = false;
    x11Support = true;
    waylandSupport = false;
    usbSupport = true;
  };

  full =
    base
    // {
      gtkSupport = true;
      gstreamerSupport = true;
      openalSupport = true;
      openclSupport = true;
      odbcSupport = true;
      netapiSupport = true;
      vaSupport = true;
      pcapSupport = true;
      v4lSupport = true;
      gphoto2Support = true;
      embedInstallers = true;
      waylandSupport = true;
    };
}
