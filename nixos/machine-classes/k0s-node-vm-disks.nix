{lib, ...}: {
  disko.devices = {
    disk.disk1 = {
      device = lib.mkDefault "/dev/vda";
      type = "disk";
      content = {
        type = "gpt";
        # Wipe old Ceph bluestore signatures that wipefs does not recognize.
        # Without this, Rook skips the OSD because it sees a foreign cluster ID.
        postCreateHook = ''
          dd if=/dev/zero of=/dev/disk/by-partlabel/disk-disk1-data bs=1M count=10
        '';
        partitions = {
          esp = {
            name = "esp";
            size = "512M";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
            };
          };
          data = {
            size = "20G";
          };
          root = {
            name = "root";
            size = "100%";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
            };
          };
        };
      };
    };
  };
}
