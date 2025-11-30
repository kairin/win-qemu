#!/bin/bash
#
# setup-runner.sh - Configure GitHub Actions self-hosted runner for win-qemu-docs
#
# Prerequisites: gh CLI authenticated, curl installed
# Usage: ./scripts/setup-runner.sh
#

set -euo pipefail

REPO="kairin/win-qemu-docs"
RUNNER_DIR="$HOME/.github-runners/win-qemu-docs"
RUNNER_VERSION="2.321.0"
RUNNER_LABELS="self-hosted,linux,x64,astro,nodejs,win-qemu-docs"

echo "🚀 GitHub Actions Self-Hosted Runner Setup"
echo "Repository: $REPO"
echo "Runner directory: $RUNNER_DIR"
echo ""

# Check prerequisites
if ! command -v gh &> /dev/null; then
    echo "❌ gh CLI not found. Install with: sudo apt install gh"
    exit 1
fi

if ! gh auth status &> /dev/null; then
    echo "❌ gh CLI not authenticated. Run: gh auth login"
    exit 1
fi

# Create runner directory
mkdir -p "$RUNNER_DIR"
cd "$RUNNER_DIR"

# Download runner if not present
if [ ! -f "run.sh" ]; then
    echo "📥 Downloading GitHub Actions runner v${RUNNER_VERSION}..."
    curl -o actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz -L \
        "https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz"

    echo "📦 Extracting runner..."
    tar xzf actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz
    rm actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz
fi

# Get registration token
echo "🔑 Getting registration token..."
TOKEN=$(gh api repos/${REPO}/actions/runners/registration-token -X POST --jq '.token')

if [ -z "$TOKEN" ]; then
    echo "❌ Failed to get registration token"
    exit 1
fi

# Configure runner
echo "⚙️ Configuring runner with labels: $RUNNER_LABELS"
./config.sh --url "https://github.com/${REPO}" \
    --token "$TOKEN" \
    --name "$(hostname)-win-qemu-docs" \
    --labels "$RUNNER_LABELS" \
    --work "_work" \
    --unattended \
    --replace

echo ""
echo "✅ Runner configured successfully!"
echo ""
echo "📋 Next steps:"
echo "1. Start runner manually: cd $RUNNER_DIR && ./run.sh"
echo "2. Or install as service: cd $RUNNER_DIR && sudo ./svc.sh install && sudo ./svc.sh start"
echo ""
echo "🔗 View runners: https://github.com/${REPO}/settings/actions/runners"
