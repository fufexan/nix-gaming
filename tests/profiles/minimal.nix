{ pkgs, ... }:
{
  virtualisation = {
    cores = 4;
    memorySize = 4096;
    qemu.options = [ "-vga none -enable-kvm -device virtio-gpu-pci,xres=720,yres=1440" ];
  };

  users.users.test = {
    isNormalUser = true;
    password = "";
  };

  services.greetd.settings.default_session = {
    command = "${pkgs.greetd.greetd}/bin/agreety --cmd /bin/sh";
  };
}
