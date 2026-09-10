#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

VM_HOME="/home/$VM_USER"

# Reclaim the space the provisioning steps above leave behind. Everything
# here is a cache or a build artifact that regenerates on demand — nothing
# an installed tool needs to run.

# Drops packages nothing depends on any more — transitive build deps and
# superseded kernel images. It won't touch the cloud image's own
# linux-image-virtual (that's a manually-installed metapackage, so apt keeps
# it even though 00-system.sh's HWE kernel supersedes it); purging that one
# is a deliberate, separate call if the ~400MB is worth it.
sudo apt-get autoremove --purge -y

# ~/.cache/pip: pipx's installer cache (06-ansible.sh)
sudo rm -rf "$VM_HOME/.cache/pip" /root/.cache/pip

# npm's cache — renovate (08-renovate.sh) installs globally as root, so its
# cache lands in root's home, not $VM_USER's.
sudo env PATH="$PATH:/usr/local/node/bin" npm cache clean --force 2>/dev/null || true
sudo rm -rf "$VM_HOME/.npm" /root/.npm

# Go's module and build caches, several GB after 03-go.sh builds
# golangci-lint/govulncheck/gosec from source. The installed binaries in
# ~/go/bin are unaffected; projects re-download their own modules.
sudo -u "$VM_USER" -H env PATH="$PATH:/usr/local/go/bin" go clean -cache -modcache

# Downloaded .debs (the big one after 09-latex.sh) and the package index,
# which "apt-get update" rebuilds.
sudo apt-get clean
sudo rm -rf /var/lib/apt/lists/*

# Logs from the build itself
sudo journalctl --rotate --vacuum-time=1s >/dev/null 2>&1 || true
sudo rm -rf /var/log/cloud-init.log /var/log/cloud-init-output.log \
  /var/log/unattended-upgrades /var/log/apt/*.log

# Packer runs this very script out of /tmp, so skip it rather than deleting
# a file bash is still reading.
sudo find /tmp /var/tmp -mindepth 1 -not -path "$0" -delete 2>/dev/null || true

# Hand the freed blocks back to the host so the VM's sparse disk.img shrinks
# instead of staying at its high-water mark. Harmless if the virtual disk
# doesn't advertise discard support.
sudo fstrim -av || true

df -h /
