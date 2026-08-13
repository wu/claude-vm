#!/usr/bin/env bash
set -euo pipefail

# renovate: datasource=node-version depName=node
NODE_VERSION=24.19.0
ARCH="$(dpkg --print-architecture)" # arm64 on Apple Silicon, amd64 on Intel
case "$ARCH" in
  amd64) NODE_ARCH=x64 ;;
  arm64) NODE_ARCH=arm64 ;;
  *)
    echo "unsupported architecture: $ARCH" >&2
    exit 1
    ;;
esac

curl -fsSL "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-${NODE_ARCH}.tar.xz" -o /tmp/node.tar.xz
sudo mkdir -p /usr/local/node
sudo tar -C /usr/local/node --strip-components=1 -xJf /tmp/node.tar.xz
rm /tmp/node.tar.xz

echo 'export PATH="$PATH:/usr/local/node/bin"' | sudo tee /etc/profile.d/node.sh >/dev/null

# npm's #!/usr/bin/env node shebang needs node on PATH; /etc/profile.d only
# takes effect in future login shells, not this one.
export PATH="$PATH:/usr/local/node/bin"

node --version
npm --version
