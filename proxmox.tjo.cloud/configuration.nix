{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:
{
  imports = [
    "${toString modulesPath}/profiles/qemu-guest.nix"
  ];

  system.stateVersion = "24.05";

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    autoResize = true;
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/ESP";
    fsType = "vfat";
  };

  boot.growPartition = true;
  boot.kernelParams = [ "console=ttyS0" ];
  boot.loader.systemd-boot.enable = true;
  #boot.loader.grub.device = "nodev";
  #boot.loader.grub.efiSupport = true;
  #boot.loader.grub.efiInstallAsRemovable = true;
  boot.loader.timeout = 0;

  system.build.qcow2 = import "${toString modulesPath}/../lib/make-disk-image.nix" {
    inherit lib config pkgs;
    name = "nixos";
    diskSize = "auto";
    format = "qcow2-compressed";
    partitionTableType = "efi";
    copyChannel = true;
    configFile = pkgs.writeText "configuration.nix" (pkgs.lib.readFile ./configuration.nix);
  };

  services.qemuGuest.enable = true;

  services.cloud-init = {
    enable = true;
    network.enable = true;
    settings = lib.mkOptionDefault {
      datasource = {
        NoCloud = { };
        ConfigDrive = { };
      };
    };
  };

  # Needed due to cloud-init.network.enable = true
  networking.useNetworkd = true;

  # Create default user
  security.sudo.wheelNeedsPassword = false;
  nix.settings.trusted-users = [ "nixos" ];
  users.users.nixos = {
    isNormalUser = true;
    password = "hunter2";
    extraGroups = [ "wheel" ];
  };

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  environment.systemPackages = [ pkgs.nginx ];
}
