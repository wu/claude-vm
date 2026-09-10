#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

# Terraform, pinned from the official release archive (the HashiCorp apt
# repo lags new Ubuntu codenames, so it can't be relied on for resolute).
# renovate: datasource=github-releases depName=hashicorp/terraform extractVersion=^v(?<version>.+)$
TERRAFORM_VERSION=1.16.2
ARCH="$(dpkg --print-architecture)" # arm64 on Apple Silicon, amd64 on Intel

curl -fsSL "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_${ARCH}.zip" -o /tmp/terraform.zip
sudo unzip -o -d /usr/local/bin /tmp/terraform.zip terraform
rm /tmp/terraform.zip

terraform version
