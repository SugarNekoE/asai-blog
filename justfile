# Compile Elm and generate the static site.
build:
    bash scripts/build.sh

# Build, then serve and watch Markdown, templates, and static assets.
dev: build
    bash scripts/site.sh watch

# Remove Hakyll's generated site and cache.
clean:
    bash scripts/site.sh clean

# Verify the generated pages and JSON contract.
check: build
    python3 scripts/check.py
    python3 scripts/check-compiler.py

# Recompile Elm after editing frontend/src.
ui:
    cd frontend && elm make src/Main.elm --optimize --output=../static/assets/elm.js

# Format source and configuration files, excluding generated output.
format:
    bash scripts/format.sh

fonts noto cjk:
    python3 scripts/fonts.py {{quote(noto)}} {{quote(cjk)}}

# Exercise the UI (run npm ci and npx playwright install chromium first).
test: check
    npm test

# Run the output locally with Cloudflare's Pages routing.
preview: build
    npx wrangler pages dev _site

# Publish to the Cloudflare Pages project configured in wrangler.jsonc.
deploy: check
    npx wrangler pages deploy _site
