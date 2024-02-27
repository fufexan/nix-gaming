{
  virtualisation = {
    cores = 4;
    memorySize = 4096;
    qemu.options = ["-vga none -enable-kvm -device virtio-gpu-pci,xres=720,yres=1440"];
  };

  users.users.test = {
    isNormalUser = true;
    password = "";
  };

  services.xserver = {
    enable = true;

    displayManager = {
      autoLogin = {
        enable = true;
        user = "test";
      };
      gdm.enable = true;
    };

    desktopManager.gnome.enable = true;
  };
}
