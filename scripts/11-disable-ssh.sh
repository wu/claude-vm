#!/usr/bin/env bash
set -euo pipefail

# Day-to-day access to the running VM is via "tart exec" over the guest
# agent's control socket (see README), never SSH. Packer's build-time
# connection is the only thing that needs sshd, and this is the last
# provisioning step, so it's safe to turn off here — covers both the
# service and its socket-activation unit (Ubuntu 22.10+), since either one
# left enabled would bring sshd back on the next connection attempt.
for unit in ssh.socket ssh.service; do
  sudo systemctl disable "$unit" 2>/dev/null || true
done

# Stopping sshd from inside the very SSH session running this command would
# sever that session before its exit status reaches Packer, so defer the
# actual stop by a couple of seconds until after this script has returned.
sudo bash -c '
  sleep 2
  for unit in ssh.socket ssh.service; do
    systemctl stop "$unit" 2>/dev/null || true
  done
' >/dev/null 2>&1 &
disown
