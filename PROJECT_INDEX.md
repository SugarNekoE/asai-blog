# Asai Blog

`sne.moe` — Obsidian Markdown → Hakyll/Pandoc → Elm → Cloudflare Pages.

## Run

```sh
devenv shell
pnpm install --frozen-lockfile
just dev
```

Use the pinned pnpm 11 version. Run `just ui` after Elm edits; restart `just dev`
after Haskell/Clay edits. Devenv supplies compilers, linters, and Chromium.

Commands: `just build`, `just preview`, `just format`, `just lint`, `just check`,
`just test`. See `just --list` for details. Run selected tests with
`just test-browser tests/test_outline.py -n 0`; artifacts go to `test-results/`.

## Source map

| Area                            | Location                                           |
| ------------------------------- | -------------------------------------------------- |
| Notes, templates, attachments   | `content/`                                         |
| Compiler, routes, feed          | `site.hs`                                          |
| Static views and Clay styles    | `src/Site/`                                        |
| Elm state, views, UI styles     | `frontend/src/`                                    |
| Browser adapters, colors, fonts | `static/assets/`                                   |
| Checks and Python browser tests | `scripts/`, `tests/`, `pyproject.toml`             |
| Environment and commands        | `devenv.nix`, `justfile`                           |
| Deployment                      | `.forgejo/workflows/deploy.yaml`, `wrangler.jsonc` |

Write notes in `content/posts/<category>/`; publish with `status: published`.
All attachments are public. Obsidian manages formatting in `content/.obsidian/`.

## Deploy

Forgejo deploys `main` after checks. It needs `CLOUDFLARE_API_TOKEN` (Pages Edit)
and `CLOUDFLARE_ACCOUNT_ID`. Manual uploads: `just deploy`; `just deploy-built`
skips checks. Pushing/deploying requires explicit approval; see [AGENTS.md](AGENTS.md).

Code: [AGPL-3.0](LICENSE). Original content: [CC BY-SA 4.0](content/LICENSE).
Font provenance/licenses: [SOURCES.md](static/assets/fonts/SOURCES.md).
