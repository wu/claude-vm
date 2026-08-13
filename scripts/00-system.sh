#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

# Disable cloud-init data sources for subsequent boots (uploaded to /tmp by
# a file provisioner). growpart keeps working, so the root partition still
# grows when the disk is resized with "tart set --disk-size".
sudo cp /tmp/99_claude_vm.cfg /etc/cloud/cloud.cfg.d/99_claude_vm.cfg

sudo apt-get update

# Hardware enablement kernel, like the upstream cirruslabs image uses
. /etc/os-release
sudo apt-get install -y "linux-generic-hwe-${VERSION_ID}"

# Guest agent for Tart VMs (makes "tart ip" and "tart exec" work)
# renovate: datasource=github-releases depName=openai/tart-guest-agent extractVersion=^v(?<version>.+)$
TART_GUEST_AGENT_VERSION=0.12.0
ARCH="$(dpkg --print-architecture)" # arm64 on Apple Silicon, amd64 on Intel

curl -fsSL -o /tmp/tart-guest-agent.deb \
  "https://github.com/openai/tart-guest-agent/releases/download/v${TART_GUEST_AGENT_VERSION}/tart-guest-agent_${TART_GUEST_AGENT_VERSION}_linux_${ARCH}.deb"
sudo apt-get install -y /tmp/tart-guest-agent.deb
rm /tmp/tart-guest-agent.deb

# The packaged systemd unit hardcodes "User=admin", which doesn't exist in
# this image — override it to $VM_USER or the agent crashes on every boot
# and "tart exec" / "tart ip" (agent-based resolution) never work.
sudo mkdir -p /etc/systemd/system/tart-guest-agent.service.d
printf '[Service]\nUser=\nUser=%s\n' "$VM_USER" |
  sudo tee /etc/systemd/system/tart-guest-agent.service.d/override.conf >/dev/null
sudo systemctl daemon-reload

# Reboot into the new kernel (Packer expects the disconnect and reconnects)
sudo reboot
