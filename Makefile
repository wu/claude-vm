# Builds the claude-vm Tart image from scratch, replicating the pipeline
# cirruslabs/linux-image-templates uses for ghcr.io/cirruslabs/ubuntu:latest:
# official Ubuntu cloud image -> raw disk -> empty tart VM -> cloud-init
# first boot -> Packer provisioning.
#
# The whole build runs under a throwaway VM name and is only swapped in for
# VM_NAME once Packer has fully provisioned it, so an existing $(VM_NAME) is
# usable right up until that final swap instead of disappearing for the
# whole build.
#
# Usage (on the Mac):
#   make            # build the whole thing (safe to re-run any time)
#   make delete     # remove the built VM
#   make clean      # drop cached artifacts to pick up a newer cloud image

VM_NAME          ?= claude-vm
BUILD_NAME       := $(VM_NAME)-build
UBUNTU_RELEASE   ?= resolute
UBUNTU_VERSION   ?= 26.04
GITHUB_COM_TOKEN ?=

# arm64 on Apple Silicon, amd64 on Intel
ARCH := $(shell uname -m | sed -e 's/x86_64/amd64/')

# The "releases/<codename>/release" tree is the tested, production-grade
# stream; "<codename>/current" is the untested daily preview build.
IMAGE_URL := https://cloud-images.ubuntu.com/releases/$(UBUNTU_RELEASE)/release/ubuntu-$(UBUNTU_VERSION)-server-cloudimg-$(ARCH).img

.PHONY: build vm delete clean renovate

build: vm cloud-init.iso
	packer init .
	packer build -var "vm_name=$(BUILD_NAME)" .
	@if tart list --format json | jq -e '.[] | select(.Name == "$(VM_NAME)" and .Running)' >/dev/null 2>&1; then \
		echo "==> $(VM_NAME) is still running - stop it whenever you're ready; waiting to swap in the new build..."; \
		while tart list --format json | jq -e '.[] | select(.Name == "$(VM_NAME)" and .Running)' >/dev/null 2>&1; do \
			sleep 5; \
		done; \
		echo "==> $(VM_NAME) stopped, swapping in the new build."; \
	fi
	tart delete $(VM_NAME) || true
	tart rename $(BUILD_NAME) $(VM_NAME)

# Empty Linux VM with the cloud image as its disk, assembled under
# BUILD_NAME so an existing $(VM_NAME) is left alone until the swap in
# "build" above. "cp -c" makes an APFS clone, so image.raw survives for the
# next build without costing space.
vm: image.raw
	tart delete $(BUILD_NAME) || true
	tart create --linux $(BUILD_NAME)
	cp -c image.raw "$$HOME/.tart/vms/$(BUILD_NAME)/disk.img"

image.qcow2:
	curl -fSL -o $@ "$(IMAGE_URL)"

image.raw: image.qcow2
	qemu-img convert -p -f qcow2 -O raw $< $@

# NoCloud datasource ISO: volume label "cidata" is what cloud-init looks for.
# hdiutil is built into macOS (no cdrtools/mkisofs needed).
cloud-init.iso: cloud-init/user-data cloud-init/meta-data cloud-init/network-config
	rm -f $@
	hdiutil makehybrid -iso -joliet -default-volume-name cidata -o $@ cloud-init/

delete:
	tart delete $(VM_NAME) || true
	tart delete $(BUILD_NAME) || true

clean:
	rm -f image.qcow2 image.raw cloud-init.iso

# Run this one inside a claude-vm clone, not on the Mac host like the
# targets above — it needs the Node/Renovate CLI that scripts/08-renovate.sh
# installs in the image. Local platform mode: no token, no PRs, just reports
# what updates are available.
#
# GITHUB_COM_TOKEN (optional): avoids "github-token-required" skips on
# github-releases lookups. Pass it in on the command line, e.g.
# make renovate GITHUB_COM_TOKEN=...
#
# RENOVATE_CONFIG_FILE points at this directory's renovate.json (the custom
# manager for the "# renovate:" marker comments), but only when Renovate
# won't find it by itself — it discovers a config through git, at the repo
# root only:
#
#   - standalone claude-vm repo: this dir IS the root, so renovate.json is
#     discovered. Passing it again as a file config layers a second, identical
#     custom manager on top and every dependency gets extracted (and listed)
#     twice.
#   - inside a larger repo (e.g. geektank-k8s): this tree is a subdirectory,
#     so nothing is discovered — not this renovate.json, not the parent's —
#     and the file has to be passed explicitly or no deps are found at all.
renovate:
	@if [ "$$(git rev-parse --show-toplevel 2>/dev/null)" = "$$(pwd)" ]; then cfg=; else cfg=RENOVATE_CONFIG_FILE=renovate.json; fi; \
	set -x; env GITHUB_COM_TOKEN=$(GITHUB_COM_TOKEN) $$cfg \
		LOG_LEVEL=debug LOG_FORMAT=json RENOVATE_PLATFORM=local renovate | bin/renovate-summary.py
