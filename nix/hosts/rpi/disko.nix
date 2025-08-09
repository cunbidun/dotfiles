{
  disko.devices = {
    disk.sd = {
      type = "disk";
      device = "/dev/mmcblk0";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            type = "EF00"; # EFI System Partition
            size = "512M";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = ["umask=0077"];
            };
          };
          root = {
            size = "100%";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
              mountOptions = ["relatime"];
            };
          };
        };
      };
    };
  };
}
