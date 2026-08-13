#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

# Hostname
sudo hostnamectl set-hostname claude-vm
echo '127.0.1.1 claude-vm' | sudo tee -a /etc/hosts >/dev/null

# Timezone
sudo timedatectl set-timezone America/Los_Angeles

# Disable unattended upgrades so apt is never locked when the VM boots
# (same trick the cirruslabs linux-runner image uses).
sudo cp /usr/share/unattended-upgrades/20auto-upgrades-disabled /etc/apt/apt.conf.d/

sudo apt-get update
sudo apt-get upgrade -y

sudo apt-get install -y \
  build-essential \
  ca-certificates \
  curl \
  fd-find \
  git \
  gnupg \
  htop \
  jq \
  ripgrep \
  sqlite3 \
  tmux \
  unzip \
  vim \
  wget \
  zip \
  zsh

# cloud-init created $VM_USER with bash (zsh wasn't installed yet) — switch now
sudo chsh -s /usr/bin/zsh "$VM_USER"

# Unlike bash's /etc/profile, zsh never sources /etc/profile.d itself, so
# the PATH exports later scripts drop there (go.sh, node.sh, ...) would
# silently only take effect for bash. Source them for login zsh shells too.
printf '%s\n' \
  'if [ -d /etc/profile.d ]; then' \
  '  for script in /etc/profile.d/*.sh; do' \
  '    [ -r "$script" ] && . "$script"' \
  '  done' \
  '  unset script' \
  'fi' |
  sudo tee -a /etc/zsh/zprofile >/dev/null

# Auto-mount tart shared directories. "nofail" keeps the VM booting
# normally when a directory isn't shared for a given run.
#
# Shared with: tart run --dir="/Volumes/tank/projects:tag=projects" \
#                       --dir="/Users/wu/.claude-vm:tag=claude" <vm>
VM_HOME="/home/$VM_USER"
sudo mkdir -p "$VM_HOME/projects" "$VM_HOME/.claude"
sudo chown "$VM_USER:$VM_USER" "$VM_HOME/projects" "$VM_HOME/.claude"
printf '%s\n' \
  "projects $VM_HOME/projects virtiofs rw,nofail 0 0" \
  "claude $VM_HOME/.claude virtiofs rw,nofail 0 0" |
  sudo tee -a /etc/fstab >/dev/null

# Catch-all automount for any other shared directories, at /mnt/shared
sudo mkdir -p /mnt/shared
echo 'com.apple.virtio-fs.automount /mnt/shared virtiofs rw,nofail 0 0' |
  sudo tee -a /etc/fstab >/dev/null
