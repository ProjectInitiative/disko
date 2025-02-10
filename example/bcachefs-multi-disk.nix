{
  disko.devices = {
    disk = {
      main = {
        device = "/dev/disk/by-path/pci-0000:02:00.0-nvme-1";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              end = "500M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };
            root = {
              name = "root";
              end = "-0";
              content = {
                type = "filesystem";
                format = "bcachefs";
                mountpoint = "/";
              };
            };
          };
        };
      };

      disk1 = {
        type = "disk";
        device = "/dev/vdc";
        content = {
          type = "gpt";
          partitions = {
            bcachefs = {
              size = "100%";
              content = {
                type = "bcachefs_member";
                name = "pool1";
                label = "fast";
                discard = true;
                dataAllowed = [ "journal" "btree" ];
              };
            };
          };
        };
      };
      disk2 = {
        type = "disk";
        device = "/dev/vdd";
        content = {
          type = "gpt";
          partitions = {
            bcachefs = {
              size = "100%";
              content = {
                type = "bcachefs_member";
                name = "pool1";
                label = "slow";
                durability = 2;
                dataAllowed = [ "user" ];
              };
            };
          };
        };
      };
      # use whole disk, ignore partitioning
      # disk3 = {
      #   type = "disk";
      #   device = "/dev/vde";
      #   content = {
      #     type = "bcachefs_member";
      #     pool = "pool1";
      #     label = "main";
      #   };
      # };
    };

    bcachefs = {
      pool1 = {
        type = "bcachefs";
        mountpoint = "/mnt/pool";
        formatOptions = [ "--compression=zstd" ];
        mountOptions = [ "verbose" "degraded" ];
      };
    };
  };
}
