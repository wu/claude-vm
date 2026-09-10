packer {
  required_plugins {
    tart = {
      source = "github.com/cirruslabs/tart"
      # renovate: datasource=github-releases depName=cirruslabs/packer-plugin-tart extractVersion=^v(?<version>.+)$
      version = "1.21.0"
    }
  }
}

# Name of the local VM produced by the build. The VM must already exist,
# assembled from the official Ubuntu cloud image — run the build through
# "make" (see Makefile), which handles that before invoking Packer.
variable "vm_name" {
  type    = string
  default = "claude-vm"
}

variable "disk_size_gb" {
  type    = number
  default = 20
}

variable "cpu_count" {
  type    = number
  default = 2
}

variable "memory_gb" {
  type    = number
  default = 4
}

# cloud-init/user-data is the source of truth for the account name — every
# other file threads it through as a variable.
locals {
  vm_user = regex("- name: (\\S+)", file("cloud-init/user-data"))[0]
}

source "tart-cli" "claude" {
  vm_name      = var.vm_name
  disk_size_gb = var.disk_size_gb
  cpu_count    = var.cpu_count
  memory_gb    = var.memory_gb
  headless     = true
  disable_vnc  = true

  # First boot attaches the cloud-init ISO, which creates the user (see
  # cloud-init/user-data) that Packer then connects as.
  run_extra_args = ["--disk", "cloud-init.iso"]
  ssh_username   = local.vm_user
  ssh_password   = local.vm_user
  ssh_timeout    = "300s"
}

build {
  sources = ["source.tart-cli.claude"]

  provisioner "file" {
    source      = "99_claude_vm.cfg"
    destination = "/tmp/99_claude_vm.cfg"
  }

  # HWE kernel + tart-guest-agent; ends with a reboot into the new kernel
  provisioner "shell" {
    scripts           = ["scripts/00-system.sh"]
    expect_disconnect = true
    environment_vars  = ["VM_USER=${local.vm_user}"]
  }

  provisioner "shell" {
    pause_before     = "10s"
    environment_vars = ["VM_USER=${local.vm_user}"]
    scripts = [
      "scripts/01-base.sh",
      "scripts/02-claude-code.sh",
      "scripts/03-go.sh",
      "scripts/04-node.sh",
      "scripts/05-terraform.sh",
      "scripts/06-ansible.sh",
      "scripts/07-packer.sh",
      "scripts/08-renovate.sh",
      "scripts/09-latex.sh",
      "scripts/10-dotfiles.sh",
      "scripts/11-cleanup.sh",
      "scripts/12-disable-ssh.sh",
    ]
  }
}
