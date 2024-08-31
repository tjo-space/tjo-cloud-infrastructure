{ lib, pkgs, ... }:
{
  system.stateVersion = "24.05";

  boot.loader.systemd-boot.enable = true;

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
