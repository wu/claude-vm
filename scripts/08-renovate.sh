#!/usr/bin/env bash
set -euo pipefail

export PATH="$PATH:/usr/local/node/bin"

# renovate: datasource=npm depName=renovate
RENOVATE_VERSION=44.79.6

sudo env PATH="$PATH" npm install -g "renovate@${RENOVATE_VERSION}"

renovate --version
