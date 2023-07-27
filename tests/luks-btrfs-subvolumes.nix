{ pkgs ? (import <nixpkgs> { })
, makeDiskoTest ? (pkgs.callPackage ../lib { }).testLib.makeDiskoTest
}:
makeDiskoTest {
  inherit pkgs;
  name = "luks-btrfs-subvolumes";
  disko-config = ../example/luks-btrfs-subvolumes.nix;
  extraTestScript = ''
  machine.succeed("cryptsetup isLuks /dev/vda2");
  machine.succeed("btrfs subvolume list / | grep -qs 'path nix$'");
  machine.succeed("btrfs subvolume list / | grep -qs 'path home$'");
  '';
}
