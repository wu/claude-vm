#!/usr/bin/env bash
set -euo pipefail

VM_HOME="/home/$VM_USER"

# Dotfiles: the same links ~/projects/dot/install.sh would create, baked in
# so clones don't need a manual install step. The dot repo arrives via the
# projects share, so the links dangle until it's mounted. Keep the list in
# sync with the repo's top-level dotfiles (re-running install.sh in the VM
# picks up anything new).
sudo -u "$VM_USER" ln -sfn "$VM_HOME/projects/dot" "$VM_HOME/dot"
for f in .emacs .vimrc .zprofile .zshrc .gitconfig; do
  sudo -u "$VM_USER" ln -sfn "$VM_HOME/projects/dot/$f" "$VM_HOME/$f"
done

# /Volumes/tank/projects -> ~/projects, so paths written on the Mac host
# resolve inside the VM too. Needs root: / is root-owned, and a failed
# mkdir in an && chain is exempt from set -e, so getting this wrong fails
# silently and the build still reports success.
sudo mkdir -p /Volumes/tank
sudo chown "$VM_USER:$VM_USER" /Volumes/tank
sudo -u "$VM_USER" ln -sfn "$VM_HOME/projects" /Volumes/tank/projects
