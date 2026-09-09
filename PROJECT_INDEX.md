# Asai Blog

Static blog built with Hakyll, Pandoc, and Elm. Content is authored in an
Obsidian vault; the generated site can be uploaded to Cloudflare Pages.

| Path                                                                                   | Purpose                                                                 |
| -------------------------------------------------------------------------------------- | ----------------------------------------------------------------------- |
| `AGENTS.md`                                                                            | Project conventions, validation, and commit rules                       |
| `devenv.nix`, `devenv.yaml`, `devenv.lock`                                             | Development environment and pinned dependencies                         |
| `justfile`                                                                             | Build, development, formatting, testing, and deployment commands        |
| `scripts/`                                                                             | Build entrypoints, artifact checks, and font generation                 |
| `pyproject.toml`                                                                       | Strict Pyright configuration and Python lint rules                      |
| `eslint.config.js`                                                                     | JavaScript lint rules for browser adapters and tests                    |
| `typings/fontTools/`                                                                   | Type stubs for the FontTools APIs used by the font generator            |
| `site.hs`, `asai-blog.cabal`, `cabal.project`                                          | Hakyll compiler and Haskell package configuration                       |
| `content/posts/<category>/`                                                            | Markdown notes; only `status: published` is published                   |
| `content/attachments/`                                                                 | Public attachments copied to the site                                   |
| `content/templates/`, `content/.obsidian/`                                             | Obsidian authoring template and settings                                |
| `src/Site/Page.hs`, `src/Site/Views.hs`                                                | Typed Haskell page shell and static content views                       |
| `src/Site/Markdown.hs`                                                                 | Markdown transforms and compiled article-outline metadata               |
| `frontend/src/Main.elm`                                                                | Application state, updates, and view composition                        |
| `frontend/src/BrowserPorts.elm`                                                        | Typed interface to native browser adapters                              |
| `frontend/src/Keyboard.elm`, `frontend/src/BrowserClock.elm`                           | Shortcut policies and browser-local clock logic                         |
| `frontend/src/Post.elm`                                                                | Note metadata and JSON decoding                                         |
| `frontend/src/Notebook.elm`, `frontend/src/Notebook/`                                  | Index composition, queries, cards, filters, and pagination              |
| `frontend/src/Layout.elm`                                                              | Navigation, headers, footer, and article outline                        |
| `frontend/src/SearchLauncher.elm`, `frontend/src/Keymap.elm`                           | Search and shortcut dialogs                                             |
| `frontend/src/IndexQuery.elm`, `frontend/src/Search.elm`, `frontend/src/LinkHints.elm` | URL state, query matching, and letter hints                             |
| `static/assets/colors.css`                                                             | Monokai Pro palette and tag color mappings                              |
| `frontend/src/Styles/`                                                                 | Scoped elm-css component styles, typography, and responsive helpers     |
| `static/assets/base.css`, `static/assets/loading.css`                                  | Browser defaults, static fallback, and pre-Elm loading styles           |
| `static/assets/article.css`, `static/assets/print.css`                                 | Pandoc article content and printable output                             |
| `static/assets/fonts.css`, `static/assets/noto.css`, `static/assets/fonts/`            | Noto font stacks, generated faces, and bundled fonts                    |
| `static/assets/browser/`, `static/assets/boot.js`                                      | Native browser adapters and startup coordination; `elm.js` is generated |
| `tests/`, `playwright.config.js`                                                       | Browser tests                                                           |
| `wrangler.jsonc`, `static/_headers`                                                    | Cloudflare Pages configuration and HTTP headers                         |
| `_site/`                                                                               | Generated website; excluded from Git                                    |

Use `devenv shell`, then `npm ci` and `just dev`. Run `just --list` for available
commands. `just check` verifies generated output; `just test` also runs browser
tests. Browser tests require Playwright Chromium or an installed Chromium set
through `CHROMIUM_PATH`.

Run `just ui` after editing Elm or its styles. Restart `just dev` after editing
Haskell modules.

Run `just format` to format source files, `just check-format` to check formatting,
or `just lint` for formatting, strict Python checks, ESLint, and ShellCheck.
`just check` also compiles Elm and Haskell and verifies the generated site.
Elm uses `elm-format`'s standard two blank lines between top-level declarations.

See [font sources and licenses](static/assets/fonts/SOURCES.md) for bundled font
provenance and regeneration. Deployment is manual; no GitHub workflow is included.
