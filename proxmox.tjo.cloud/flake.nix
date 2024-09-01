{
  description = "Basic NixOS qcow2 image with CloudInit for Proxmox";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
  };
  outputs =
    { self, nixpkgs }:
    {
      nixosConfigurations = {
        build-qcow2 = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./qcow2.nix
            ./configuration.nix
          ];
        };
      };
    };
}
