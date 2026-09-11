#!/usr/bin/env bash
set -euo pipefail

VM_HOME="/home/$VM_USER"

# The installer takes the version to install as its first argument; the
# published versions match the @anthropic-ai/claude-code npm package's.
# renovate: datasource=npm depName=@anthropic-ai/claude-code
CLAUDE_CODE_VERSION=2.1.268
# Install Claude Code for $VM_USER with the native installer (lands in
# $VM_HOME/.local/bin and wires up PATH in the shell profile).
sudo -u "$VM_USER" -H env CLAUDE_CODE_VERSION="$CLAUDE_CODE_VERSION" \
  bash -c 'curl -fsSL https://claude.ai/install.sh | bash -s "$CLAUDE_CODE_VERSION"'

sudo -u "$VM_USER" -H "$VM_HOME/.local/bin/claude" --version

# Claude Code writes a default ~/.claude.json the first time the binary
# runs (the --version check above). Replace it with a symlink into
# ~/.claude — a virtiofs share back to the host — so config changes made
# in the VM persist on the host and carry into future clones.
sudo -u "$VM_USER" -H bash -euc 'rm -f "$HOME/.claude.json"; ln -sfn .claude/claude.json "$HOME/.claude.json"'
