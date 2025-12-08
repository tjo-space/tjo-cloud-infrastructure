# Always use devbox environment to run commands.
set shell := ["devbox", "run"]
# Load dotenv
set dotenv-load

export SOPS_AGE_KEY_FILE := if os() == "linux" {`echo "$HOME/.config/sops/age/keys.txt"`} else { `echo "$HOME/Library/Application Support/sops/age/keys.txt"` }

mod dns 'dns'
mod id 'id.tjo.cloud'
mod k8s 'k8s.tjo.cloud'
mod s3 's3.tjo.cloud'
mod network 'network.tjo.cloud'
mod ingress 'ingress.tjo.cloud'
mod proxmox 'proxmox.tjo.cloud'
mod postgresql 'postgresql.tjo.cloud'
mod mail 'mail.tjo.cloud'
mod monitor 'monitor.tjo.cloud'

import 'secrets.justfile'

post-pull: dot-env-decrypt secrets-md-decrypt tofu-state-decrypt ansible-secrets-decrypt
pre-commit: dot-env-encrypt secrets-md-encrypt tofu-state-encrypt ansible-secrets-encrypt lint format

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
