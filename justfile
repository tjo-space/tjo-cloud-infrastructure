# Always use devbox environment to run commands.
set shell := ["devbox", "run"]
# Load dotenv
set dotenv-load

mod k8s 'k8s.tjo.cloud'
mod network 'network.tjo.cloud'
mod ingress 'ingress.tjo.cloud'

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

tofu-state-encrypt:
  #!/bin/bash
  for file in $(find tofu.tfstate); do
    sops \
      --encrypt \
      --input-type=json \
      --output-type=json \
      $file > ${file}.encrypted
  done

tofu-state-decrypt:
  #!/bin/bash
  for file in $(find tofu.tfstate.encrypted); do
    sops \
      --decrypt \
      --input-type=json \
      --output-type=json \
      $file > ${file%.encrypted}
  done

default:
  @just --list

lint:
  @tofu fmt -check -recursive .
  @tflint --recursive
