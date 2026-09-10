# Compile Elm and generate the static site.
build:
    bash scripts/build.sh

# Build, then serve and watch Markdown and static assets.
dev: build
    bash scripts/site.sh watch

# Remove Hakyll's generated site and cache.
clean:
    bash scripts/site.sh clean

# Verify the generated pages and JSON contract.
check: lint build
    python3 scripts/check.py
    python3 scripts/check-compiler.py

check-python:
    pyright
    ruff check scripts typings
    ruff format --check scripts typings

# Recompile Elm after editing frontend/src.
ui:
    cd frontend && elm make src/Main.elm src/Startup.elm src/CodeBlock.elm --optimize --output=../static/assets/elm.js

# Format source and configuration files, excluding generated output.
format:
    bash scripts/format.sh

# Check source formatting without rewriting files.
check-format:
    bash scripts/format.sh check

# Lint source files; Elm and Haskell compiler checks also run in `just check`.
lint: check-format check-python
    ./node_modules/.bin/eslint --max-warnings 0 static/assets tests *.js
    shellcheck scripts/*.sh .envrc

fonts noto cjk:
    python3 scripts/fonts.py {{ quote(noto) }} {{ quote(cjk) }}

# Exercise the UI (run npm ci and npx playwright install chromium first).
test: check
    npm test

# Run the output locally with Cloudflare's Pages routing.
preview: build
    npx wrangler pages dev _site

# Publish to the Cloudflare Pages project configured in wrangler.jsonc.
deploy: check
    npx wrangler pages deploy _site
