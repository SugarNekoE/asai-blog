# Asai Blog

A technical notebook for `sne.moe`: write in Obsidian, generate pages with
Hakyll/Pandoc, browse with Elm, and host on Cloudflare Pages.

## Start locally

From the repository root:

```bash
devenv shell
pnpm install --frozen-lockfile
just dev
```

Open the local address printed by `just dev`. Run `just ui` after Elm edits;
restart `just dev` after Haskell or Clay edits. Devenv supplies the compilers,
linters, Python browser tests, and Chromium.

Devenv enables Corepack, which selects the pnpm version pinned in `package.json`.
Keep pnpm on version 11 for compatibility with the Nix runner's Linux environment.

## Write notes

Open `content/` as an Obsidian vault. Enable the Templates core plugin and use
`templates/Note.md`. Write in `posts/<category>/` with unique, stable filenames;
the first folder determines the category. Change `status: draft` to
`status: published` when ready for the website.

Published notes cannot link to missing or unpublished notes. All attachments
are public. Drafts are excluded from the website, but committing them to Git
makes them accessible to anyone who can read the repository.

## Commands

Run these inside `devenv shell`. See `just --list` for everything available.

| Command                                           | Purpose                                              |
| ------------------------------------------------- | ---------------------------------------------------- |
| `just build`                                      | Compile Elm and rebuild the static site cleanly      |
| `just dev` / `just preview`                       | Watch locally / preview with Cloudflare routing      |
| `just format` / `just check-format`               | Format source / check formatting                     |
| `just lint`                                       | Formatting, Python, JavaScript, and shell checks     |
| `just check`                                      | Lint, build, and verify output and compiler behavior |
| `just test`                                       | Full checks plus browser tests                       |
| `just test-browser tests/test_search.py -k focus` | Selected browser tests against the current build     |
| `just deploy`                                     | Check, build, and upload to Cloudflare Pages         |

Browser artifacts go to `test-results/`; use `-n 0` for serial test debugging.
`just deploy-built` uploads the existing `_site/` without checks; CI uses it only
once `just check` passes. Both deployment commands accept Wrangler options,
such as `--branch main`.

## Where things live

| Area                                       | Files                                                                                         |
| ------------------------------------------ | --------------------------------------------------------------------------------------------- |
| Notes and authoring                        | `content/posts/`, `content/attachments/`, `content/templates/`, `content/.obsidian/`          |
| Build, routes, JSON, feed                  | `site.hs`                                                                                     |
| Static views, Markdown, bootstrap metadata | `src/Site/`                                                                                   |
| Static/article/loading/print styles        | `src/Site/Styles/` and `src/Site/Styles.hs`                                                   |
| App, navigation, search, note lists        | `frontend/src/` (`Main`, `Layout`, `Notebook`, `SearchLauncher`, `Panels`)                    |
| Startup, copy controls, keyboard, hints    | `frontend/src/Startup/`, `CodeBlock.elm`, `Keyboard.elm`, `LinkHints/`                        |
| Interactive styles                         | `frontend/src/Styles/`                                                                        |
| Browser adapters, palette, fonts           | `static/assets/`: `browser/`, `colors.css`, `fonts.css`, `noto.css`, `fonts/`                 |
| Checks and browser tests                   | `scripts/`, `tests/`, `pyproject.toml`, `typings/`                                            |
| Environment and deployment                 | `devenv.*`, `justfile`, `wrangler.jsonc`, `static/_headers`, `.forgejo/workflows/deploy.yaml` |

`_site/` and compiler caches are generated and untracked. Read
[AGENTS.md](AGENTS.md) before automated edits; font provenance is in
[fonts/SOURCES.md](static/assets/fonts/SOURCES.md).

## Deploy through Forgejo

The [workflow](.forgejo/workflows/deploy.yaml) deploys pushes to `main` and manual
runs on `main` to the **asai-blog** Cloudflare Pages project. It uses **acs-nix**,
enables `nix-command`/`flakes`, installs Node before checkout, and runs the build
through devenv. Keep `BOOTSTRAP_NIXPKGS` aligned with the nixpkgs revision in
`devenv.lock`.

Create the Pages project with production branch `main`, enable Forgejo Actions,
and add these repository Actions secrets:

| Secret                  | Value                                                                    |
| ----------------------- | ------------------------------------------------------------------------ |
| `CLOUDFLARE_API_TOKEN`  | Token with **Account → Cloudflare Pages → Edit**, scoped to your account |
| `CLOUDFLARE_ACCOUNT_ID` | The account containing the Pages project                                 |

Forgejo runs `pnpm install --frozen-lockfile` and `just check`, then uploads `_site/`. Configure the custom
domain in Cloudflare. Use a separate Git branch to sync unfinished work without
triggering production deployment. See [Cloudflare's CI setup guide](https://developers.cloudflare.com/pages/how-to/use-direct-upload-with-continuous-integration/).
