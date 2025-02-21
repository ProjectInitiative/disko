# lib/types/bcachefs.nix
{ config, options, lib, diskoLib, ... }:
{
  options = {
    name = lib.mkOption {
      type = lib.types.str;
      default = config._module.args.name;
      description = "Name of the bcachefs pool";
    };

    type = lib.mkOption {
      type = lib.types.enum [ "bcachefs" ];
      default = "bcachefs";
      internal = true;
      description = "Type";
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

    content = diskoLib.deviceType { parent = config; device = "/dev/bcachefs/${config.name}"; };

    _meta = lib.mkOption {
      internal = true;
      readOnly = true;
      type = diskoLib.jsonType;
      default = lib.optionalAttrs (config.content != null) (config.content._meta ["bcachefs" config.name ]);
      
      description = "Metadata";
    };

    _create = diskoLib.mkCreateOption {
      inherit config options;
      # default = ''
      #   echo BCACHEFS POSITION
      #   # Read member info from runtime dir
      #   readarray -t member_args < <(cat "$disko_devices_dir/bcachefs-${config.name}-members" || true)
        
      #   # Add format options
      #   args=()
      #   args+=("''${member_args[@]}")
      #   args+=(${toString config.formatOptions})

      #   # Get the first device (primary)
      #   primary_device=$(echo "''${member_args[0]}" | cut -d' ' -f1)

      #   # Format if needed
      #   if ! bcachefs show-super "$primary_device" >/dev/null 2>&1; then
      #     bcachefs format --force "''${args[@]}"
      #     udevadm trigger --subsystem-match=block
      #     udevadm settle
      #   fi

      #   # Always get and store the UUID
      #   mkdir -p /etc/disko-uuids
      #   bcachefs show-super "$primary_device" | grep Ext | awk '{print $3}' > /etc/disko-uuids/bcachefs-${config.name}
      #   ${lib.optionalString (config.content != null) config.content._create}
      # '';
      default = ''
          echo BCACHEFS POSITION
          # Read member info from runtime dir - one argument per line
          readarray -t members < <(cat "$disko_devices_dir/bcachefs-${config.name}-members" || true)
          readarray -t member_args < <(cat "$disko_devices_dir/bcachefs-${config.name}-args" || true)
    
          # Format if needed
          if bcachefs show-super "''${members[0]}" >/dev/null 2>&1 && ! (bcachefs show-super "''${members[0]}" 2>&1 | grep -qi "Not a bcachefs superblock"); then
            # Superblock exists and is valid, no reformat needed
            echo "Found existing bcachefs filesystem, skipping format."
          else
            # Need to format - either show-super failed with non-zero exit code
            # or it returned "Not a bcachefs superblock" message
            echo "No valid bcachefs filesystem found, formatting..."
            # bcachefs format --force "''${member_args[@]}" ${toString config.formatOptions}
              # Add some sleep and sync to ensure all previous operations are complete

            sync
            sleep 1
  
            # Try formatting with additional error handling
            format_attempts=0
            max_attempts=3
            format_success=false
  
            while [ $format_attempts -lt $max_attempts ] && [ "$format_success" = "false" ]; do
              format_attempts=$((format_attempts + 1))
              echo "Format attempt $format_attempts of $max_attempts..."
    
              if bcachefs format --force "''${member_args[@]}" ${toString config.formatOptions}; then
                format_success=true
                echo "Format successful"
              else
                format_exit=$?
                echo "Format failed with exit code $format_exit, waiting before retry..."
                sync
                sleep 2
              fi
            done
  
            if [ "$format_success" = "false" ]; then
              echo "Failed to format bcachefs filesystem after $max_attempts attempts"
              exit 1
            fi

            udevadm trigger --subsystem-match=block
            udevadm settle
          fi

          # Always get and store the UUID
          mkdir -p /etc/disko-uuids
          bcachefs show-super "''${members[0]}" | grep Ext | awk '{print $3}' > /etc/disko-uuids/bcachefs-${config.name}
          ${lib.optionalString (config.content != null) config.content._create}
      '';
    };

    _mount = diskoLib.mkMountOption {
      inherit config options;
      default = {
        fs.${config.mountpoint} = ''
          if ! findmnt "${config.mountpoint}" > /dev/null 2>&1; then
            # Read UUID from the file we created
            uuid=$(cat /etc/disko-uuids/bcachefs-${config.name})
            mount -t bcachefs UUID="$uuid" "${config.mountpoint}" \
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
      default = let
        uuidFile = "/etc/disko-uuids/bcachefs-${config.name}";
        uuid = if builtins.pathExists uuidFile
               then lib.removeSuffix "\n" (builtins.readFile uuidFile)
               else "not-yet-created";
      in [
        { boot.supportedFilesystems = [ "bcachefs" ]; }
        {
          fileSystems.${config.mountpoint} = {
            device = "UUID=${uuid}";
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
