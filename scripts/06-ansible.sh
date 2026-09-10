#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

# pipx installs a pinned Ansible into its own venv, rather than whatever
# version happens to be current in the Ubuntu archive.
sudo apt-get install -y pipx

# renovate: datasource=pypi depName=ansible
ANSIBLE_VERSION=14.4.0

# --include-deps: the "ansible" package itself only ships the
# "ansible-community" script — the actual CLI (ansible, ansible-playbook,
# ansible-galaxy, ...) lives in its ansible-core dependency, which pipx
# skips exposing by default.
sudo -u "$VM_USER" -H pipx install --include-deps "ansible==${ANSIBLE_VERSION}"

sudo -u "$VM_USER" -H "/home/$VM_USER/.local/bin/ansible" --version
