# Always use devbox environment to run commands.
set shell := ["devbox", "run"]
# Load dotenv
set dotenv-load

mod k8s 'k8s.tjo.cloud'

default:
  @just --list

lint:
  @tofu fmt -check -recursive .
  @tflint --recursive
