# Asai Blog

Static blog built with Hakyll, Pandoc, and Elm. Content is authored in an
Obsidian vault; the generated site can be uploaded to Cloudflare Pages.

| Path                                                                          | Purpose                                                                      |
| ----------------------------------------------------------------------------- | ---------------------------------------------------------------------------- |
| `AGENTS.md`                                                                   | Project conventions, validation, and commit rules                            |
| `devenv.nix`, `devenv.yaml`, `devenv.lock`                                    | Development environment and pinned dependencies                              |
| `justfile`                                                                    | Build, development, formatting, testing, and deployment commands             |
| `scripts/`                                                                    | Build entrypoints, artifact checks, and font generation                      |
| `pyproject.toml`                                                              | Strict Python checks and pytest configuration                                |
| `eslint.config.js`                                                            | JavaScript lint rules for browser adapters and tooling                       |
| `typings/fontTools/`                                                          | Type stubs for the FontTools APIs used by the font generator                 |
| `site.hs`, `asai-blog.cabal`, `cabal.project`                                 | Hakyll compiler and Haskell package configuration                            |
| `content/posts/<category>/`                                                   | Markdown notes; only `status: published` is published                        |
| `content/attachments/`                                                        | Public attachments copied to the site                                        |
| `content/templates/`, `content/.obsidian/`                                    | Obsidian authoring template and settings                                     |
| `src/Site/Page.hs`, `src/Site/Views.hs`                                       | Typed Haskell page shell and static content views                            |
| `src/Site/Markdown.hs`                                                        | Markdown transforms and compiled article-outline metadata                    |
| `src/Site/Bootstrap.hs`                                                       | Typed page metadata and safely encoded bootstrap JSON                        |
| `src/Site/Styles.hs`, `src/Site/Styles/`                                      | Clay-generated base, article, code, loading, and print styles                |
| `frontend/src/Main.elm`                                                       | Application state, updates, and view composition                             |
| `frontend/src/Startup.elm`, `frontend/src/Startup/`                           | elm/http startup worker, index validation, font requests, and loading stages |
| `frontend/src/CodeBlock.elm`                                                  | Elm copy-button components, feedback, and reset timers                       |
| `frontend/src/Panels.elm`                                                     | Exclusive panel state and focus/scroll destinations                          |
| `frontend/src/BrowserPorts.elm`                                               | Typed interface to native browser adapters                                   |
| `frontend/src/Keyboard.elm`, `frontend/src/BrowserClock.elm`                  | Shortcut policies and browser-local clock logic                              |
| `frontend/src/Post.elm`                                                       | Note metadata and JSON decoding                                              |
| `frontend/src/Notebook.elm`, `frontend/src/Notebook/`                         | Index composition, queries, cards, filters, and pagination                   |
| `frontend/src/Layout.elm`                                                     | Navigation, headers, footer, and article outline                             |
| `frontend/src/SearchLauncher.elm`, `frontend/src/Keymap.elm`                  | Search and shortcut dialogs                                                  |
| `frontend/src/IndexQuery.elm`, `frontend/src/Search.elm`                      | URL state and query matching                                                 |
| `frontend/src/LinkHints.elm`, `frontend/src/LinkHints/`                       | Hint eligibility, geometry, label selection, and letter assignment           |
| `static/assets/colors.css`                                                    | Monokai Pro palette and tag color mappings                                   |
| `frontend/src/Styles/`                                                        | Scoped elm-css component styles, typography, and responsive helpers          |
| `static/assets/fonts.css`, `static/assets/noto.css`, `static/assets/fonts/`   | Noto font stacks, generated faces, and bundled fonts                         |
| `static/assets/boot.js`                                                       | Browser entry point                                                          |
| `static/assets/browser/runtime.js`, `static/assets/browser/page.js`           | Native Elm initialization, page data, storage, and history adapters          |
| `static/assets/browser/clipboard.js`, `static/assets/browser/link-targets.js` | Clipboard access and native DOM measurement/hit testing                      |
| `static/assets/browser/`                                                      | Native focus, keyboard, modal, asset, and trusted-content adapters           |
| `tests/test_*.py`                                                             | Python Playwright browser tests                                              |
| `tests/conftest.py`, `tests/helpers.py`, `tests/cdp.py`                       | Browser/server fixtures, request gates, and typed Chromium inspection        |
| `wrangler.jsonc`, `static/_headers`                                           | Cloudflare Pages configuration and HTTP headers                              |
| `_site/`                                                                      | Generated website; excluded from Git                                         |

Use `devenv shell`, then `npm ci` and `just dev`. Run `just --list` for available
commands. `just check` verifies generated output; `just test` also runs the Python
browser suite. Devenv provides pytest, Playwright, four-worker test execution,
and a Chromium executable through `CHROMIUM_PATH` on Linux.

Use `just test-browser` against an existing build, or select scenarios with
`just test-browser tests/test_search.py -k 'focus or keyboard'`. Use `-n 0` for
serial debugging. Each worker serves `_site/` on an available local port;
screenshots, PDFs, and failure traces go to `test-results/`.

Run `just ui` after editing Elm or its styles. Restart `just dev` after editing
Haskell modules, including Clay styles. The startup worker, main interface, and
copy-button components compile into one bundle. Hakyll emits the Clay stylesheets
directly into `_site/assets/`.

`cabal.project` points Cabal and HLS at the compiler in `.devenv/profile`, including
its Nix-provided libraries. Initialize the profile with `devenv shell` and restart
the editor's Haskell language server after changing dependencies.

Run `just format` to format source files, `just check-format` to check formatting,
or `just lint` for formatting, strict Python checks, ESLint, and ShellCheck.
`just check` also compiles Elm and Haskell and verifies the generated site.
Elm uses `elm-format`'s standard two blank lines between top-level declarations.

See [font sources and licenses](static/assets/fonts/SOURCES.md) for bundled font
provenance and regeneration. Deployment is manual; no GitHub workflow is included.
