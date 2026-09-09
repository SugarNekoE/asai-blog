# Asai Blog — Agent Rules

## Project

This repository is Asai Blog, a technical blog for `sne.moe`. Markdown is
authored in the `content/` Obsidian vault. Hakyll and Pandoc generate static HTML,
JSON, and an Atom feed; Elm provides the interactive interface. Cloudflare Pages
serves the generated `_site/` directory. See `PROJECT_INDEX.md` for the file index
and basic commands.

## Source Ownership

- `site.hs`: Hakyll rules, Pandoc processing, categories, routes, JSON, and feed.
- `content/posts/<category>/`: Markdown posts and drafts.
- `content/attachments/`: public assets copied to the site.
- `content/templates/` and `content/.obsidian/`: authoring templates and settings.
- `templates/`: static HTML templates and the no-JavaScript fallback.
- `frontend/src/Main.elm`: UI state, views, navigation, and filters.
- `static/assets/`: shared CSS and the JavaScript boundary for browser APIs and
  Elm ports. `static/assets/elm.js` is generated.
- `justfile` and `scripts/`: build, formatting, and verification commands.
- `devenv.nix`, `devenv.yaml`, and `devenv.lock`: the development environment.
- `wrangler.jsonc` and `static/_headers`: Pages configuration and HTTP headers.

## Implementation Rules

- Use `just` for project commands; do not introduce a Makefile. Use devenv as
  the sole environment manager locally and in CI. Keep environment definitions
  and runtime wrappers in `devenv.nix`; do not add standalone shell definitions
  or a separate Nix configuration directory.
- Keep source and configuration readable and expanded. Use `just format` or the
  relevant configured formatter; never hand-minify source files.
- Comment only non-obvious rationale or constraints; do not narrate the code.
- Keep palette values and color mappings in `static/assets/colors.css`, using
  named Monokai Pro color tokens. Layout CSS consumes these tokens; tag mappings
  use exact `data-tag` values and share colors across badges, chips, and pickers.
- Edit source rather than `_site/`, `_cache/`, `.build/`, `dist-newstyle/`,
  `frontend/elm-stuff/`, or `static/assets/elm.js`. Regenerate build outputs and
  leave them untracked. Do not reformat lockfiles; retain legitimate dependency
  updates when needed for the task.
- Keep Markdown conversion in Hakyll/Pandoc and interactive state in Elm. Use
  JavaScript for browser integration through the existing ports. Keep the JSON
  producer, Elm decoder, startup flags, and tests consistent when contracts change.
- Preserve standalone article URLs and readable static HTML when JavaScript or
  the JSON index is unavailable. Only trusted, repository-authored HTML belongs
  in the `blog-content` boundary.
- Each post has one category, derived from the first folder below
  `content/posts/`. Nested folders inherit that category; YAML does not override
  it. Published posts directly inside `content/posts/` must fail the build.
- Only `status: published` notes enter the site, JSON, or feed. Keep draft
  exclusion and rejection of missing or unpublished wiki-link targets intact.
  All files in `content/attachments/` are public, even if used only by drafts.
- Keep note filenames unique and existing public URLs stable unless a requested
  change explicitly requires migration. Use a clean production rebuild so removed
  or unpublished notes do not remain in `_site/`.

## UI Conventions

Preserve these choices unless the user requests a change:

- Site name: **Asai Blog**. The header name links to All Notes; the breadcrumb
  shows the current category and links back to its index on reading pages.
  There is no About page or Markdown filename tab.
- The left sidebar lists categories. Clickable note tags add to the index's
  multi-tag filter; all selected tags must match alongside category and search.
  Selected tags have removable chips and persist as repeated `tag` URL parameters.
- Categories are navigation context, not filters. “Clear filters” removes only
  selected tags; it preserves the current category and search text.
- Paginate the index after applying its category, tags, search, and sort order.
  Default to 10 notes per page, with 30/50/100 options. Reset to page 1 when the
  result set, sort order, or page size changes, and preserve pagination in the URL.
- “Search notes” opens a modal launcher on every page with a darkened backdrop.
  Search title/description keywords, `#tag` prefixes, or a leading `/category`;
  allow combined queries. Preserve keyboard navigation, focus containment,
  Escape/backdrop dismissal, and the index's independent filters.
- `?` opens keyboard shortcuts and `/` opens search outside text fields. Panels
  share modal behavior and must not remain open on top of each other.
- With panels closed, `t` toggles theme, `o` toggles the reading outline, Enter
  opens the selected index note, and `f` shows letter hints for visible links
  and category navigation buttons.
  Keep native Enter behavior on focused controls. Hint input takes precedence
  over page shortcuts; Escape, scrolling, or resizing cancels hints.
  With panels and hints closed, Escape clears the focused control and its outline
  without changing input values or filters. Tab resumes normal keyboard focus.
  Highlight note titles only while their own row is hovered or their title has
  keyboard focus; the remembered Enter target must not keep a row highlighted.
- “On this page” belongs in a transparent right-hand article panel, with a
  responsive layout on narrow screens, rather than in the left sidebar.
- `Shift+I` toggles Immersive Mode outside text fields: widen content and hide
  sidebar, outline, normal header, and footer. Keep a minimal borderless header
  with the linked λ / Asai Blog brand, mode label, and clickable Shift+I exit hint.
  Suppress the main container's focus outline; retain focus indicators on controls.
  Close open panels and hints on entry;
  preserve outline preference and index state for restoration on exit.
- Keep print layout in `static/assets/print.css`: content only, A4 margins,
  dark text on white, and no site controls or overlays. Preserve complete code,
  tables, and images across pages, including in fallback and immersive states.
- Bundle Noto Sans, Noto Sans Mono, and Noto CJK before generic system fallbacks.
  Use the bundled Noto Sans Symbols and Symbols 2 for icons, with centered icon
  containers. Keep shared font stacks in `static/assets/fonts.css`, generated
  font faces in `static/assets/noto.css`, and fonts with their OFL licenses in
  `static/assets/fonts/`. Preserve CJK coverage and load subsets on demand.
- The header clock uses browser-local time in `yyyy/mm/dd HH:mm` format.
- Show “Please Be Patient” with the current loading stage while startup assets
  are pending. Reveal the site after fonts, notes, and document assets settle;
  preserve a readable static fallback for failures, timeouts, and no JavaScript.
- Footer timings use `loading 67ms / rendered 9ms`, without zero padding.
  Loading means navigation start to the browser load event; rendering means
  Elm initialization to its first paint opportunity, not subsequent updates.
- The sidebar shows the `sne.moe` link above “CC-BY-SA 4.0”; link the
  license name to `https://creativecommons.org/licenses/by-sa/4.0/`. Place the
  `?` keymap button beside these two lines, not in the page footer.

## Validation and Review

- Run checks appropriate to the change. `just check` builds both layers and
  verifies generated artifacts, links, categories, drafts, and compiler behavior.
- For UI changes, run the relevant Playwright tests against current generated
  output (`npm test`, or `npm test -- --grep '...'`). Use `just test` for the full
  build/check/browser suite. Install tool dependencies with `npm ci` as needed.
- On NixOS, set `CHROMIUM_PATH` to a Nix-provided Chromium when needed. Use the
  existing Pages runtime wrapper for `just preview`.
- Check desktop and mobile rendering when layout changes. Do not add tests that
  only mirror trivial edits; do not claim checks passed unless they were run.
- For documentation-only changes, verify accuracy against current files and
  check formatting; a full application build is unnecessary.
- Present changed behavior, validation results, material risks, and any remaining
  review items. Keep source formatting intact and run `git diff --check`.

## Git Authorization

All changes must be reviewed by a human before delivery.

- Never run `git add`, `git commit`, `git push`, `git merge`, `git cherry-pick`,
  or a history-rewriting command on your own initiative. Preserve files already
  staged by the human, but do not stage agent-authored changes without approval.
- After editing, present the changed behavior, validation, risks, and unresolved
  checklist items. Completed implementation is not permission to commit.
- Never perform destructive or irreversible operations outside the requested
  scope without explicit human confirmation.

After explicit approval, commits must be signed off and follow
`type(scope): subject`.

- Use `git commit -s` so the `Signed-off-by:` trailer is present.
- Use a lowercase imperative subject with no trailing period and a meaningful
  scope such as `hakyll`, `elm`, `styles`, `content`, `tests`, `tooling`, `pages`,
  `docs`, or `agents`.
- Never add a `Co-authored-by:` trailer.

Examples: `feat(elm): add multi-tag filters`, `fix(hakyll): exclude draft posts`,
and `docs(agents): document blog workflows`.

## Deployment Authorization

Local builds and previews are not publishing. Do not run `just deploy`,
`wrangler pages deploy`, or change production configuration without explicit
authorization. Approval to commit does not by itself authorize pushing or
deploying. No GitHub workflow is included; deployment is manual.
