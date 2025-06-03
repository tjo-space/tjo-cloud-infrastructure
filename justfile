# Always use devbox environment to run commands.
set shell := ["devbox", "run"]
# Load dotenv
set dotenv-load

mod id 'id.tjo.cloud'
mod k8s 'k8s.tjo.cloud'
mod network 'network.tjo.cloud'
mod ingress 'ingress.tjo.cloud'
mod proxmox 'proxmox.tjo.cloud'
mod postgresql 'postgresql.tjo.cloud'

export SOPS_AGE_KEY_FILE := if os() == "linux" {`echo "$HOME/.config/sops/age/keys.txt"`} else { `echo "$HOME/Library/Application Support/sops/age/keys.txt"` }

default:
  @just --list

dot-env-encrypt:
  sops \
    --encrypt \
    --input-type=dotenv \
    --output-type=dotenv \
    .env > .env.encrypted

dot-env-decrypt:
  sops \
    --decrypt \
    --input-type=dotenv \
    --output-type=dotenv \
    .env.encrypted > .env

# We do not use sops as state files can be large.
# And we want to use gzip on them to make them smaller (from 17MB to 4MB).
tofu-state-encrypt:
  #!/bin/bash
  for file in $(find -name tofu.tfstate -o -name terraform.tfstate)
  do
    echo "Encrypting $file"
    cat $file | gzip --stdout | age --encrypt -R {{source_directory()}}/tofu.keys > ${file}.encrypted
  done

# We do not use sops as state files can be large.
# And we want to use gzip on them to make them smaller (from 17MB to 4MB).
[confirm('Are you sure? This will overwrite your local state files! Ireversable operation!')]
tofu-state-decrypt:
  #!/bin/bash
  for file in $(find -name tofu.tfstate.encrypted -o -name terraform.tfstate.encrypted)
  do
    echo "Decrypting $file"
    cat $file | age --decrypt -i "${SOPS_AGE_KEY_FILE}" | gzip --decompress --stdout > ${file%.encrypted}
  done

lint:
  @tofu fmt -check -recursive .
  @tflint --recursive

format:
  @tofu fmt -recursive .
  @tflint --recursive
