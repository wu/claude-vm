#!/usr/bin/env bash
set -euo pipefail

# renovate: datasource=golang-version depName=go
GO_VERSION=1.26.5
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
# renovate: datasource=go depName=github.com/golangci/golangci-lint
GOLANGCI_LINT_VERSION=1.62.2
# renovate: datasource=go depName=golang.org/x/vuln
GOVULNCHECK_VERSION=1.6.0
# renovate: datasource=go depName=github.com/securego/gosec/v2
GOSEC_VERSION=2.28.0

sudo -u "$VM_USER" -H env PATH="$PATH:/usr/local/go/bin" \
  go install "github.com/golangci/golangci-lint/cmd/golangci-lint@v${GOLANGCI_LINT_VERSION}"
sudo -u "$VM_USER" -H env PATH="$PATH:/usr/local/go/bin" \
  go install "golang.org/x/vuln/cmd/govulncheck@v${GOVULNCHECK_VERSION}"
sudo -u "$VM_USER" -H env PATH="$PATH:/usr/local/go/bin" \
  go install "github.com/securego/gosec/v2/cmd/gosec@v${GOSEC_VERSION}"

"/home/$VM_USER/go/bin/golangci-lint" version
