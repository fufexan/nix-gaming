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
    ldapSupport = false;
    vkd3dSupport = false;
    embedInstallers = false;
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
      ldapSupport = true;
      vkd3dSupport = true;
      embedInstallers = true;
    };
}
