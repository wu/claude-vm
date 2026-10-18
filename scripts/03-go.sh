#!/usr/bin/env bash
set -euo pipefail

# renovate: datasource=golang-version depName=go
GO_VERSION=1.27.2
ARCH="$(dpkg --print-architecture)" # arm64 on Apple Silicon, amd64 on Intel

curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-${ARCH}.tar.gz" -o /tmp/go.tar.gz
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf /tmp/go.tar.gz
rm /tmp/go.tar.gz

echo 'export PATH="$PATH:/usr/local/go/bin:$HOME/go/bin"' | sudo tee /etc/profile.d/go.sh >/dev/null

/usr/local/go/bin/go version

# Installed via `go install`, not a prebuilt release binary, so each tool is
# built against this VM's own Go toolchain. A prebuilt golangci-lint built
# with an older Go can't parse newer language features (e.g. go1.25+ syntax
# pulled in via grpc/x/net/x/text) in its embedded type-checker.
#
# Pinned to match the versions used by a downstream project's CI lint/scan
# workflow.
# renovate: datasource=go depName=github.com/golangci/golangci-lint/v2
GOLANGCI_LINT_VERSION=2.14.0
# renovate: datasource=go depName=golang.org/x/vuln
GOVULNCHECK_VERSION=1.9.0
# renovate: datasource=go depName=github.com/securego/gosec/v2
GOSEC_VERSION=2.29.0
# gosec 2.29.0 pins x/tools v0.49.0, which can't read the export data Go
# 1.27.2 writes ("export data version 5 is greater than maximum supported
# version 4"). Build it against a newer x/tools until a gosec release pins
# v0.50.0 or later, then go back to a plain go install.
# renovate: datasource=go depName=golang.org/x/tools
GOSEC_X_TOOLS_VERSION=0.52.0

sudo -u "$VM_USER" -H env PATH="$PATH:/usr/local/go/bin" \
  go install "github.com/golangci/golangci-lint/v2/cmd/golangci-lint@v${GOLANGCI_LINT_VERSION}"
sudo -u "$VM_USER" -H env PATH="$PATH:/usr/local/go/bin" \
  go install "golang.org/x/vuln/cmd/govulncheck@v${GOVULNCHECK_VERSION}"

GOSEC_BUILD_DIR="$(sudo -u "$VM_USER" mktemp -d)"
sudo -u "$VM_USER" -H env PATH="$PATH:/usr/local/go/bin" bash -c '
  set -euo pipefail
  cd "$1"
  go mod init gosec-build
  go get "github.com/securego/gosec/v2/cmd/gosec@v$2" "golang.org/x/tools@v$3"
  go build -o "$HOME/go/bin/gosec" github.com/securego/gosec/v2/cmd/gosec
' _ "$GOSEC_BUILD_DIR" "$GOSEC_VERSION" "$GOSEC_X_TOOLS_VERSION"
rm -rf "$GOSEC_BUILD_DIR"

"/home/$VM_USER/go/bin/golangci-lint" version
