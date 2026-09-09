#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
if ghc-pkg latest hakyll >/dev/null 2>&1; then
  mkdir -p .build
  ghc -Wall -threaded -O0 -isrc -outputdir .build site.hs -o .build/site
  exec .build/site "$@"
else
  exec cabal run site -- "$@"
fi
