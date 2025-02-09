{ config, options, lib, diskoLib, parent, device, ... }:
{
  options = {
    type = lib.mkOption {
      type = lib.types.enum [ "bcachefs_member" ];
      description = "bcachefs member device type";
    };
    device = lib.mkOption {
      type = lib.types.str;
      default = device;
      description = "Device path";
    };
    pool = lib.mkOption {
      type = lib.types.str;
      description = "Name of the bcachefs pool this device belongs to";
    };
    label = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Device label";
    };
    discard = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable TRIM/discard";
    };
    fsSize = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Filesystem size";
    };
    bucketSize = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Bucket size";
    };
    durability = lib.mkOption {
      type = lib.types.nullOr lib.types.int;
      default = null;
      description = "Replication factor";
    };
    dataAllowed = lib.mkOption {
      type = lib.types.listOf (lib.types.enum [ "journal" "btree" "user" ]);
      default = [];
      description = "Allowed data types";
    };
    _parent = lib.mkOption {
      internal = true;
      default = parent;
    };
    _meta = lib.mkOption {
      internal = true;
      readOnly = true;
      type = lib.types.functionTo diskoLib.jsonType;
      default = dev: {
        deviceDependencies.bcachefs.${config.pool} = [ dev ];
      };
      description = "Metadata";
    };
    _create = diskoLib.mkCreateOption {
      inherit config options;
      default = ''
        echo "${config.device}" >> "$disko_devices_dir"/bcachefs_${lib.escapeShellArg config.pool}
      '';
    };
    _mount = diskoLib.mkMountOption {
      inherit config options;
      default = {};
    };
    _unmount = diskoLib.mkUnmountOption {
      inherit config options;
      default = {};
    };
    _config = lib.mkOption {
      internal = true;
      readOnly = true;
      default = [];
      description = "NixOS configuration";
    };
    _pkgs = lib.mkOption {
      internal = true;
      readOnly = true;
      type = lib.types.functionTo (lib.types.listOf lib.types.package);
      default = pkgs: [ pkgs.bcachefs-tools ];
      description = "Packages";
    };
  };
}
