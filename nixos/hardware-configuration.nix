# Dummy hardware-configuration.nix
# インストーラー生成ファイルに置き換える
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];
  boot.loader.grub.device = "/dev/sda";
}
