#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

# Packer, pinned from the official release archive (the HashiCorp apt
# repo lags new Ubuntu codenames, so it can't be relied on for resolute).
# renovate: datasource=github-releases depName=hashicorp/packer extractVersion=^v(?<version>.+)$
PACKER_VERSION=1.16.0
ARCH="$(dpkg --print-architecture)" # arm64 on Apple Silicon, amd64 on Intel

curl -fsSL "https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_linux_${ARCH}.zip" -o /tmp/packer.zip
sudo unzip -o -d /usr/local/bin /tmp/packer.zip packer
rm /tmp/packer.zip

packer version
