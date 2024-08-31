{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    xc = {
      url = "github:joerdav/xc";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      nixos-generators,
      xc,
      ...
    }:
    let
      pkgsForSystem =
        system:
        import nixpkgs {
          inherit system;
          overlays = [ (final: prev: { xc = xc.packages.${system}.xc; }) ];
        };
      allVMs = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllVMs =
        f:
        nixpkgs.lib.genAttrs allVMs (
          system:
          f {
            inherit system;
            pkgs = pkgsForSystem system;
          }
        );
    in
    {
      packages = forAllVMs (
        { system, pkgs }:
        {
          vm = nixos-generators.nixosGenerate {
            format = "qcow-efi";
            system = system;

            specialArgs = {
              pkgs = pkgs;
            };

            modules = [
              # Pin nixpkgs to the flake input, so that the packages installed
              # come from the flake inputs.nixpkgs.url.
              (
                { ... }:
                {
                  nix.registry.nixpkgs.flake = nixpkgs;
                }
              )
              # Apply the rest of the config.
              ./configuration.nix
            ];
          };
        }
      );
    };
}
