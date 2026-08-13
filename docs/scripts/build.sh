#!/usr/bin/env bash
# Run the Jekyll site locally (build or serve).
#
# Uses a modern Jekyll stack; the deployed site is built server-side by
# GitHub Pages on its own Jekyll snapshot.
#
# Usage:
#   ./scripts/build.sh            # build _site/
#   ./scripts/build.sh serve      # preview at http://localhost:4000/neocities-red/
#   ./scripts/build.sh build --drafts
set -euo pipefail
cd "$(dirname "$0")/.."

CMD="${1:-build}"
shift || true

bundle exec jekyll "$CMD" "$@"
