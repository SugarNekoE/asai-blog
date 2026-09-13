# Agent rules

Setup and source map: [PROJECT_INDEX.md](PROJECT_INDEX.md).

## Development

- Preserve user edits/staged files and stay in scope.
- Use `just`, devenv, pnpm, and `pnpm exec`. Keep environment definitions/wrappers
  in `devenv.nix`; no Makefile or separate Nix environment. Keep dependency locks
  consistent; never reformat them.
- Edit source only; leave generated output/caches and `static/assets/elm.js` untracked.
- Hakyll/Pandoc owns Markdown; Elm owns UI state; JS adapters own native browser APIs.
  Keep modules focused and update producers, decoders, flags, and tests together.
- Use `Html.Styled`, elm-css, `Styles.Responsive.rules`, and Clay. Preserve Monokai
  tokens/tag mappings in `colors.css` and bundled Noto fonts, stacks, and licenses.
- Use configured formatters and strict Pyright/Ruff. Comment only on non-obvious
  reasons. Let Obsidian format its settings; follow `.gitignore` for tracked vault files.
- Publish only `status: published`. Categories come from the first posts subfolder;
  reject published posts at the root and links to missing/unpublished notes.
  Keep filenames unique, URLs stable, and rebuild cleanly. All attachments are public.
- Preserve tested UI/fallback behavior. Only trusted repository HTML enters
  `blog-content`. Wait for fonts/index/assets and drain the worker queue before Main;
  retain timeout/late-response protection. Elm owns copy timers; clipboard writes
  run immediately. Hide uninitialized controls and omit toolbars from Atom.
- Current-section highlighting is text-only and must not steal focus. Keep local
  `yyyy/mm/dd HH:mm` time; timings cover navigation start→load and Main init→first paint opportunity.

## Checks

Use `just check` for build/compiler changes. For UI changes, rebuild, run relevant
`just test-browser` cases, and inspect changed desktop/mobile layouts. `just test`
runs everything. Keep tests in strict Python; JS snippets execute only in the browser.
Documentation needs accuracy/formatting checks only. Run `git diff --check` and
report changes, checks actually run, and blockers.

## Approval

Human review is required. Never stage, commit, push, merge, cherry-pick, or rewrite
history without explicit approval. Destructive actions outside the requested scope
also require explicit approval.
Completed work is not commit permission.

After approval: split independent changes, review `git diff --cached`, and use
`git commit -s` with `type(scope): subject` (lowercase imperative, no final period).
Scopes: `hakyll`, `elm`, `styles`, `content`, `tests`, `tooling`, `pages`, `docs`, `agents`.
Keep note, Obsidian, and code changes separate. Never add `Co-authored-by:`.

Push/deploy approval is separate. Forgejo deploys pushes/manual runs on `main`.
`just deploy`, `just deploy-built`, Wrangler uploads, and production settings
require explicit deployment approval.
