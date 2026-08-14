{
  description = "TJO.cloud infrastructure";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      rec {
        devShells.default = pkgs.mkShellNoCC {
          TENV_AUTO_INSTALL = "true";
          ANSIBLE_HOST_KEY_CHECKING = "false";

          packages = with pkgs; [
            step-ca
            step-cli
            kubectl
            cilium-cli
            kubelogin-oidc
            talosctl
            kubernetes-helm
            tflint
            age
            tenv
            gomplate
            just
            moreutils
            cmctl
            inetutils
            argocd
            haproxy
            garage
            cloud-init
            ansible
            grafana-alloy
            caddy
            opentofu
          ];
        };
      }
    );
}
