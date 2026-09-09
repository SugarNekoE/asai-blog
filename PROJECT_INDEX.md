# Asai Blog

Static blog built with Hakyll, Pandoc, and Elm. Content is authored in an
Obsidian vault; the generated site can be uploaded to Cloudflare Pages.

| Path                                                                        | Purpose                                                             |
| --------------------------------------------------------------------------- | ------------------------------------------------------------------- |
| `AGENTS.md`                                                                 | Project conventions, validation, and commit rules                   |
| `devenv.nix`, `devenv.yaml`, `devenv.lock`                                  | Development environment and pinned dependencies                     |
| `justfile`                                                                  | Build, development, formatting, testing, and deployment commands    |
| `scripts/`                                                                  | Build entrypoints, artifact checks, and font generation             |
| `site.hs`, `asai-blog.cabal`, `cabal.project`                               | Hakyll compiler and Haskell package configuration                   |
| `content/posts/<category>/`                                                 | Markdown notes; only `status: published` is published               |
| `content/attachments/`                                                      | Public attachments copied to the site                               |
| `content/templates/`, `content/.obsidian/`                                  | Obsidian authoring template and settings                            |
| `templates/`                                                                | Static HTML and JavaScript-free fallback views                      |
| `frontend/src/`                                                             | Elm interface, search, filters, pagination, and keyboard navigation |
| `static/assets/colors.css`                                                  | Monokai Pro palette and tag color mappings                          |
| `static/assets/style.css`, `static/assets/print.css`                        | Screen and print layouts                                            |
| `static/assets/fonts.css`, `static/assets/noto.css`, `static/assets/fonts/` | Noto font stacks, generated faces, and bundled fonts                |
| `static/assets/*.js`                                                        | Browser integration; `elm.js` is generated                          |
| `tests/`, `playwright.config.js`                                            | Browser tests                                                       |
| `wrangler.jsonc`, `static/_headers`                                         | Cloudflare Pages configuration and HTTP headers                     |
| `_site/`                                                                    | Generated website; excluded from Git                                |

Use `devenv shell`, then `npm ci` and `just dev`. Run `just --list` for available
commands. `just check` verifies generated output; `just test` also runs browser
tests. Browser tests require Playwright Chromium or an installed Chromium set
through `CHROMIUM_PATH`.

See [font sources and licenses](static/assets/fonts/SOURCES.md) for bundled font
provenance and regeneration. Deployment is manual; no GitHub workflow is included.
