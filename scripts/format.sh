#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

./node_modules/.bin/prettier --write \
  '.prettierrc.json' \
  '*.{md,json,jsonc,yaml}' \
  '.zed/*.json' \
  'content/**/*.{md,json,svg}' \
  'frontend/elm.json' \
  'static/assets/*.{css,js,svg}' \
  'templates/*.html' \
  'tests/*.js' \
  'playwright.config.js'

elm-format frontend/src --yes
ormolu --mode inplace site.hs
nixfmt devenv.nix
ruff format scripts/*.py
