#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
shopt -s globstar

case "${1:-write}" in
  write)
    prettier_mode=--write
    elm_mode=--yes
    ormolu_mode=inplace
    nixfmt_args=()
    ruff_args=()
    shfmt_mode=-w
    just_args=()
    ;;
  check)
    prettier_mode=--check
    elm_mode=--validate
    ormolu_mode=check
    nixfmt_args=(--check)
    ruff_args=(--check)
    shfmt_mode=-d
    just_args=(--check)
    ;;
  *)
    echo "Usage: $0 [write|check]" >&2
    exit 2
    ;;
esac

pnpm exec prettier "$prettier_mode" \
  '.prettierrc.json' \
  '*.{md,json,jsonc,yaml}' \
  '!pnpm-lock.yaml' \
  '.zed/*.json' \
  'content/**/*.{md,json,svg}' \
  'frontend/elm.json' \
  'static/assets/*.{css,js,svg}' \
  'static/assets/browser/*.js' \
  'static/assets/fonts/SOURCES.md' \
  '*.js'

elm-format frontend/src "$elm_mode"
ormolu --mode "$ormolu_mode" site.hs src/**/*.hs
nixfmt "${nixfmt_args[@]}" devenv.nix
ruff format "${ruff_args[@]}" scripts typings tests
shfmt -s -i 2 -ci "$shfmt_mode" scripts/*.sh .envrc
just --unstable --fmt "${just_args[@]}"
