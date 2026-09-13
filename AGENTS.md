# Working on Asai Blog

Asai Blog serves `sne.moe`. Obsidian Markdown goes through Hakyll/Pandoc into
static HTML, JSON, and Atom; Elm adds the interactive UI. See
[PROJECT_INDEX.md](PROJECT_INDEX.md) for setup, commands, and the source map.

## Before changing anything

- Preserve the user's edits and staged files. Keep changes within the requested scope.
- Follow the review and Git authorization rules below before staging or publishing.

## Implementation

- Use `just` commands and devenv locally and in CI. Keep environment definitions
  and runtime wrappers in `devenv.nix`; do not add a Makefile or separate Nix environment.
- Use pnpm for JavaScript dependencies and `pnpm exec` for project tools. Keep
  `package.json` and `pnpm-lock.yaml` consistent; CI uses `--frozen-lockfile`.
- Edit source, not generated files: `_site/`, `_cache/`, `.build/`, `dist-newstyle/`,
  `frontend/elm-stuff/`, and `static/assets/elm.js`. Leave outputs untracked.
  Do not reformat lockfiles; retain intentional dependency updates.
- Keep Markdown processing in Hakyll/Pandoc, interactive state in Elm, and native
  browser operations in small JavaScript port adapters. Update producers, decoders,
  startup flags, and tests together when contracts change.
- Keep feature views independent of `Main`, using focused state and typed callbacks.
  Use `Html.Styled`, typed elm-css, and `Styles.Responsive.rules` for interactive UI;
  use Clay for static, article, loading, and print styles.
- Keep palette and tag colors in `static/assets/colors.css` using named Monokai Pro
  tokens and exact `data-tag` mappings. Preserve bundled Noto fonts, CJK coverage,
  symbol fonts, and licenses; share font stacks through `fonts.css`.
- Use configured formatters, including standard Elm spacing. Keep Python strictly
  typed and validated with Pyright/Ruff; FontTools stubs belong in `typings/fontTools/`.
  Comment on non-obvious reasons, not what the code does.
- Track portable Obsidian settings, themes, and snippets allowed by `.gitignore`;
  keep workspace state, caches, and installed plugin files local. Let Obsidian
  manage formatting throughout `content/.obsidian/`.

## Content and rendering

- Only `status: published` notes enter HTML, JSON, and Atom. Reject wiki links to
  missing or unpublished notes. Everything in `content/attachments/` is public.
- Each post's category comes from the first folder below `content/posts/`, including
  nested posts. YAML cannot override it; published posts at the posts root must fail.
- Keep filenames unique and public URLs stable. Rebuild cleanly so removed or
  unpublished notes disappear from `_site/`.
- Preserve readable static pages when JavaScript or the index fails. Only trusted,
  repository-authored HTML may enter `blog-content`.
- Startup waits for fonts, notes, and document assets. The Elm worker validates the
  index; initialize `Main` after its queue drains. Late responses must not replace
  a revealed fallback. Keep loading stages and timeout behavior.
- Hakyll owns code toolbars/hosts; Elm owns copy state and timers. Native clipboard
  writes run immediately on the port request. Hide uninitialized controls, ignore
  stale reset timers, and omit toolbars from Atom.

## Preserve existing UI behavior

Unless requested otherwise, preserve the keyboard, focus, modal, filtering,
responsive, and fallback behavior covered by `tests/`. In particular:

- Tags combine with AND; category/search context survives clearing tags. Keep URL
  state and pagination (10/30/50/100), resetting the page when results or order change.
- Search and keymap dialogs are exclusive and contain focus on controls. Preserve
  search keyboard selection after pointer use, native Enter, hint precedence, and
  separate pointer/Tab focus tracking. Shortcuts must respect text inputs.
- Keep the outline on the right and reserve its desktop space. Index and article
  content share width and gutters; only article Immersive Mode widens the layout.
  It closes panels/hints and restores the outline preference on exit.
  Default the outline to hidden when the side panel does not fit; `o` can open
  a bounded, scrollable list above the article on smaller screens.
- Print only content, with A4 margins and complete code, tables, and images.
- Keep the local clock format `yyyy/mm/dd HH:mm`. Footer loading time ends at the
  browser load event; render time covers main Elm initialization to its first paint
  opportunity. Display timings as `loading 67ms / rendered 9ms`.

## Validate and report

- Run `just check` for build/compiler changes. For UI changes, rebuild and run
  relevant `just test-browser` scenarios; inspect desktop/mobile layouts when changed.
  `just test` runs the full suite. Documentation needs accuracy and formatting checks only.
- Keep browser tests in Python with isolated contexts and a free-port server per
  worker. JavaScript snippets are for browser execution only; invoke init functions.
  Preserve request gates and failure artifacts. Use devenv's Chromium and Pages wrapper.
- Avoid tests that merely repeat trivial edits. Run `git diff --check`, report what
  changed and what passed, and identify remaining risks or blockers. Never claim
  a check passed without running it.

## Human Review and Git Authorization

All changes must be reviewed by a human before delivery.

- Never run `git add`, `git commit`, `git push`, `git merge`, `git cherry-pick`,
  or a history-rewriting command on your own initiative. Preserve files the user
  already staged, but do not stage new agent-authored changes without approval.
- After editing, present the changed behavior, validation, risks, and unresolved
  checklist items. A completed implementation is not permission to commit.
- Never perform irreversible or destructive operations outside the requested
  scope without explicit human confirmation.
- Split independent changes into focused commits. Review `git diff --cached`
  before committing; keep unrelated note, Obsidian setting, and code changes separate.

After explicit approval, commits must be signed off and follow:
`type(scope): subject`.

- Use `git commit -s` so the `Signed-off-by:` trailer is present.
- Use a lowercase imperative subject with no trailing period and a meaningful
  scope: `hakyll`, `elm`, `styles`, `content`, `tests`, `tooling`, `pages`, `docs`,
  or `agents`.
- Never add a `Co-authored-by:` trailer.

Examples: `feat(elm): add tag filters`, `docs(content): add a note on types`,
`ci(pages): add forgejo deployment`.

Commit approval does not authorize pushing or deployment. The Forgejo workflow
deploys pushes to `main` and manual runs on `main` to Cloudflare Pages. Running
`just deploy`, `just deploy-built`, Wrangler uploads, or changing production
settings also requires explicit authorization.
