# Always use devbox environment to run commands.
set shell := ["devbox", "run"]
# Load dotenv
set dotenv-load

export SOPS_AGE_KEY_FILE := if os() == "linux" {`echo "$HOME/.config/sops/age/keys.txt"`} else { `echo "$HOME/Library/Application Support/sops/age/keys.txt"` }

mod external-dns 'dns'

mod ca 'ca.tjo.cloud'
mod dns 'dns.tjo.cloud'
mod id 'id.tjo.cloud'
mod ingress 'ingress.tjo.cloud'
mod k8s 'k8s.tjo.cloud'
mod mail 'mail.tjo.cloud'
mod monitor 'monitor.tjo.cloud'
mod network 'network.tjo.cloud'
mod postgresql 'postgresql.tjo.cloud'
mod proxmox 'proxmox.tjo.cloud'
mod s3 's3.tjo.cloud'

import 'secrets.justfile'

encrypt-all: dot-env-encrypt secrets-md-encrypt tofu-state-encrypt tofu-secrets-encrypt ansible-secrets-encrypt
decrypt-all: dot-env-decrypt secrets-md-decrypt tofu-state-decrypt tofu-secrets-decrypt ansible-secrets-decrypt

post-pull: decrypt-all
pre-commit: encrypt-all lint format

default:
  @just --list

lint:
  @tofu fmt -check -recursive .
  @tflint --recursive
  @find . -type f -name "config.alloy*" -exec alloy fmt -t {} \;
  @find . -type f -name "Caddyfile" -exec caddy fmt {} > /dev/null \;
  @find . -type f -name "Caddyfile" -exec caddy validate --config {} \;

format:
  @tofu fmt -recursive .
  @tflint --recursive
  @find . -type f -name "config.alloy*" -exec alloy fmt -w {} \;
  @find . -type f -name "Caddyfile" -exec caddy fmt -w {} \;

dependencies:
  ansible-galaxy role install rywillia.ssh-copy-id
