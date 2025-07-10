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

post-pull: dot-env-decrypt secrets-md-decrypt tofu-state-decrypt
pre-commit: dot-env-encrypt secrets-md-encrypt tofu-state-encrypt

default:
  @just --list

_encrypt path:
  #!/bin/bash
  file="{{path}}"

  echo "Encrypting ${file}"
  if cat ${file}.sha256sum | sha256sum --check --status
  then
    echo " - matches existing hash, skipping"
  else
    cat $file | gzip --stdout | age --encrypt -R {{source_directory()}}/age.keys > ${file}.encrypted
    sha256sum $file > ${file}.sha256sum
  fi

_decrypt path:
  echo "Decrypting $file"
  cat {{path}}.encrypted | age --decrypt -i "${SOPS_AGE_KEY_FILE}" | gzip --decompress --stdout > {{path}}

dot-env-encrypt:
  @just _encrypt .env

dot-env-decrypt:
  @just _decrypt .env

secrets-md-encrypt:
  @just _encrypt SECRETS.md

secrets-md-decrypt:
  @just _decrypt SECRETS.md

# We do not use sops as state files can be large.
# And we want to use gzip on them to make them smaller (from 17MB to 4MB).
tofu-state-encrypt:
  #!/usr/bin/env bash
  for file in $(find -name tofu.tfstate -o -name terraform.tfstate)
  do
    just _encrypt $file
  done

# We do not use sops as state files can be large.
# And we want to use gzip on them to make them smaller (from 17MB to 4MB).
[confirm('Are you sure? This will overwrite your local state files! Ireversable operation!')]
tofu-state-decrypt:
  #!/usr/bin/env bash
  for file in $(find -name tofu.tfstate.encrypted -o -name terraform.tfstate.encrypted)
  do
    just _decrypt $file
  done

lint:
  @tofu fmt -check -recursive .
  @tflint --recursive

format:
  @tofu fmt -recursive .
  @tflint --recursive
