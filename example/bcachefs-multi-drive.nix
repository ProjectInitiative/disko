{
  disko.devices = {
    disk = {
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
                pool = "pool1";
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
                pool = "pool1";
                label = "slow";
                durability = 2;
                dataAllowed = [ "user" ];
              };
            };
          };
        };
      };
      # use whole disk, ignore partitioning
      disk3 = {
        type = "disk";
        device = "/dev/vde";
        content = {
          type = "bcachefs_member";
          pool = "pool1";
          label = "main";
        };
      };
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
