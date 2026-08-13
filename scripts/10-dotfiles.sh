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
  src="$VM_HOME/projects/dot/$f"
  # During the image build the share isn't mounted, so every source is
  # missing and the dangling links are expected — only complain about a file
  # that's absent from a dot repo that is actually there (i.e. when this runs
  # inside a booted VM). Either way a missing file is a warning, never fatal:
  # one dotfile disappearing from the repo shouldn't fail the build.
  if [ -d "$VM_HOME/projects/dot" ] && [ ! -e "$src" ]; then
    echo "warning: $src not found - linking $VM_HOME/$f anyway" >&2
  fi
  sudo -u "$VM_USER" ln -sfn "$src" "$VM_HOME/$f" ||
    echo "warning: could not link $VM_HOME/$f -> $src" >&2
done

# /Volumes/tank/projects -> ~/projects, so paths written on the Mac host
# resolve inside the VM too. Needs root: / is root-owned, and a failed
# mkdir in an && chain is exempt from set -e, so getting this wrong fails
# silently and the build still reports success.
sudo mkdir -p /Volumes/tank
sudo chown "$VM_USER:$VM_USER" /Volumes/tank
sudo -u "$VM_USER" ln -sfn "$VM_HOME/projects" /Volumes/tank/projects
