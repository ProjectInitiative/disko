{ config, options, lib, diskoLib, ... }:
{
  options = {
    type = lib.mkOption {
      type = lib.types.enum [ "bcachefs" ];
      description = "bcachefs pool type";
    };
    name = lib.mkOption {
      type = lib.types.str;
      default = config._module.args.name;
      description = "Name of the bcachefs pool";
    };
    formatOptions = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Additional options for bcachefs format";
    };
    mountpoint = lib.mkOption {
      type = lib.types.str;
      description = "Mount point for the bcachefs pool";
    };
    mountOptions = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "defaults" ];
      description = "Options to pass to mount";
    };
    _meta = lib.mkOption {
      internal = true;
      readOnly = true;
      type = diskoLib.jsonType;
      default = {};
    };
    _create = diskoLib.mkCreateOption {
      inherit config options;
      default = ''
        readarray -t pool_devices < <(cat "$disko_devices_dir"/bcachefs_${lib.escapeShellArg config.name})
        if [ "''${#pool_devices[@]}" -eq 0 ]; then
          echo "no devices found for bcachefs pool ${config.name}. Did you misspell the pool name?" >&2
          exit 1
        fi

        # Check if any of the devices need formatting
        needs_format=0
        for device in "''${pool_devices[@]}"; do
          if ! bcachefs show-super "$device" >/dev/null 2>&1; then
            needs_format=1
            break
          fi
        done

        if [ "$needs_format" -eq 1 ]; then
          # Build device-specific arguments for each device
          args=()
          
          # Add all devices and their options
          for device in "''${pool_devices[@]}"; do
            args+=("$device")
          done

          # Add format options
          args+=(${toString config.formatOptions})
          
          bcachefs format --force "''${args[@]}"
          udevadm trigger --subsystem-match=block
          udevadm settle
        fi
      '';
    };
    _mount = diskoLib.mkMountOption {
      inherit config options;
      default = {
        fs.${config.mountpoint} = ''
          if ! findmnt "${config.mountpoint}" > /dev/null 2>&1; then
            readarray -t pool_devices < <(cat "$disko_devices_dir"/bcachefs_${lib.escapeShellArg config.name})
            UUID=$(bcachefs show-super "''${pool_devices[0]}" | grep Ext | awk '{print $3}')
            mount -t bcachefs UUID="$UUID" "${config.mountpoint}" \
              ${lib.concatMapStringsSep " " (opt: "-o ${opt}") config.mountOptions} \
              -o X-mount.mkdir
          fi
        '';
      };
    };
    _unmount = diskoLib.mkUnmountOption {
      inherit config options;
      default = {
        fs.${config.mountpoint} = ''
          if findmnt "${config.mountpoint}" > /dev/null 2>&1; then
            umount "${config.mountpoint}"
          fi
        '';
      };
    };
    _config = lib.mkOption {
      internal = true;
      readOnly = true;
      default = [
        { boot.supportedFilesystems = [ "bcachefs" ]; }
        {
          fileSystems.${config.mountpoint} = {
            device = "UUID=placeholder"; # Real UUID is determined at mount time
            fsType = "bcachefs";
            options = config.mountOptions;
          };
        }
      ];
    };
    _pkgs = lib.mkOption {
      internal = true;
      readOnly = true;
      type = lib.types.functionTo (lib.types.listOf lib.types.package);
      default = pkgs: [ pkgs.bcachefs-tools ];
    };
  };
}
