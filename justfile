# Always use devbox environment to run commands.
set shell := ["devbox", "run"]
# Load dotenv
set dotenv-load

mod id 'id.tjo.cloud'
mod k8s 'k8s.tjo.cloud'
mod network 'network.tjo.cloud'
mod ingress 'ingress.tjo.cloud'
mod v2ingress 'v2.ingress.tjo.cloud'
mod proxmox 'proxmox.tjo.cloud'
mod postgresql 'postgresql.tjo.cloud'
mod mail 'mail.tjo.cloud'

export SOPS_AGE_KEY_FILE := if os() == "linux" {`echo "$HOME/.config/sops/age/keys.txt"`} else { `echo "$HOME/Library/Application Support/sops/age/keys.txt"` }

import 'secrets.justfile'

post-pull: dot-env-decrypt secrets-md-decrypt tofu-state-decrypt
pre-commit: dot-env-encrypt secrets-md-encrypt tofu-state-encrypt lint format

default:
  @just --list

lint:
  @tofu fmt -check -recursive .
  @tflint --recursive

format:
  @tofu fmt -recursive .
  @tflint --recursive
