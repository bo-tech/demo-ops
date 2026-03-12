{ ... }:

{
  system.stateVersion = "25.11";

  microvm = {
    hypervisor = "qemu";
    vcpu = 4;
    mem = 16384;
    qemu.extraArgs = [ "-cpu" "host" ];

    volumes = [
      {
        mountPoint = "/var";
        image = "var.img";
        size = 20480;
      }
      {
        mountPoint = null;
        image = "ceph.img";
        size = 20480;
        autoCreate = false;
      }
    ];

    shares = [ {
      proto = "virtiofs";
      tag = "ro-store";
      source = "/nix/store";
      mountPoint = "/nix/.ro-store";
    } ];
  };
}
