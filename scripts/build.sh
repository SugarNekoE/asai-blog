#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p static/assets
(
  cd frontend
  elm make src/Main.elm src/Startup.elm --optimize --output=../static/assets/elm.js
)
# Rebuild removes stale pages when notes are deleted or become drafts.
bash scripts/site.sh rebuild
