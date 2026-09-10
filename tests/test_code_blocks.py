import re

from playwright.sync_api import Browser, BrowserContext, Page, expect

from tests.helpers import bounds, content_text

ARTICLE = "/posts/plain-text-to-a-small-web/"


def test_elm_copy_controls_isolate_pending_requests_and_ignore_stale_reset_timers(
    page: Page,
) -> None:
    page.clock.install()
    page.add_init_script(r"""(() => {
      window.copyRequests = [];
      Object.defineProperty(navigator, 'clipboard', {
        value: {
          writeText: (text) =>
            new Promise((resolve) => {
              window.copyRequests.push({ text, resolve, active: navigator.userActivation.isActive });
            }),
        },
      });
    })()""")
    page.goto(ARTICLE)
    expect(page.locator(".workspace")).to_be_visible()
    blocks = page.locator(".code-block")
    first = blocks.nth(0).locator(".code-copy")
    second = blocks.nth(1).locator(".code-copy")
    blocks.nth(0).hover()
    first.click()
    expect(first).to_have_text("Copying…")
    first.click()
    assert page.evaluate("() => window.copyRequests.length") == 1
    blocks.nth(1).hover()
    second.click()
    expect(second).to_have_text("Copying…")
    assert page.evaluate(
        "() => window.copyRequests.map((request) => request.active)"
    ) == [True, True]
    assert (
        page.evaluate("() => window.copyRequests.map((request) => request.text)")
        == blocks.locator("pre code").all_text_contents()
    )
    page.evaluate("() => window.copyRequests[0].resolve()")
    expect(first).to_have_text("Copied")
    expect(second).to_have_text("Copying…")
    page.clock.fast_forward(2000)
    first.click()
    expect(first).to_have_text("Copying…")
    page.clock.fast_forward(600)
    expect(first).to_have_text("Copying…")
    page.evaluate(r"""() => {
      window.copyRequests[1].resolve();
      window.copyRequests[2].resolve();
    }""")
    expect(blocks.locator(".code-copy")).to_have_text(["Copied", "Copied"])
    page.clock.run_for(2600)
    expect(blocks.locator(".code-copy")).to_have_text(["Copy", "Copy"])


def test_elm_copy_controls_work_on_the_static_article_when_index_loading_fails(
    page: Page,
) -> None:
    page.route("**/api/posts.json", lambda route: route.abort())
    page.add_init_script(r"""(() => {
      Object.defineProperty(navigator, 'clipboard', {
        value: {
          writeText: async (text) => {
            window.copiedCode = text;
          },
        },
      });
    })()""")
    page.goto(ARTICLE)
    expect(page.locator("#static-content")).to_be_visible()
    expect(page.locator(".workspace")).to_have_count(0)
    block = page.locator(".code-block").first
    block.hover()
    block.get_by_role("button", name="Copy code", exact=True).click()
    expect(block.locator(".code-copy")).to_have_text("Copied")
    assert page.evaluate("() => window.copiedCode") == content_text(
        block.locator("pre code")
    )


def test_code_toolbars_label_languages_and_copy_only_the_selected_highlighted_code(
    page: Page, context: BrowserContext
) -> None:
    context.grant_permissions(["clipboard-read", "clipboard-write"])
    page.goto(ARTICLE)
    expect(page.locator(".workspace")).to_be_visible()
    blocks = page.locator(".code-block")
    expect(blocks.locator(".code-language")).to_have_text(["haskell", "elm"])
    expect(blocks.locator(".code-copy")).to_have_count(2)
    first = blocks.first
    copy = first.get_by_role("button", name="Copy code", exact=True)
    expect(copy).to_have_css("opacity", "0")
    first.hover()
    expect(copy).to_have_css("opacity", "1")
    page.screenshot(path="test-results/code-toolbar-desktop.png")
    for block in blocks.all():
        text = content_text(block.locator("pre code"))
        block.hover()
        block.get_by_role("button", name="Copy code", exact=True).click()
        expect(block.locator(".code-copy")).to_have_text("Copied")
        assert page.evaluate("() => navigator.clipboard.readText()") == text
    page.keyboard.press("t")
    page.keyboard.press("Shift+I")
    expect(page.locator(".workspace")).to_have_class(re.compile("is-immersive"))
    expect(blocks.locator(".code-copy")).to_have_count(2)
    page.emulate_media(media="print")
    for toolbar in blocks.locator(".code-toolbar").all():
        expect(toolbar).to_be_hidden()
    expect(first.locator("pre code")).to_be_visible()


def test_copy_is_keyboard_accessible_and_reports_clipboard_failure_without_claiming_success(
    page: Page,
) -> None:
    page.add_init_script(r"""(() => {
      Object.defineProperty(navigator, 'clipboard', {
        value: {
          writeText: async () => {
            throw new Error('Clipboard denied');
          },
        },
      });
    })()""")
    page.goto(ARTICLE)
    expect(page.locator(".workspace")).to_be_visible()
    copy = page.locator(".code-copy").first
    page.keyboard.press("Tab")
    copy.focus()
    expect(copy).to_have_css("opacity", "1")
    expect(copy).to_have_css("outline-style", "solid")
    copy.press("Enter")
    expect(copy).to_have_text("Copy failed")
    expect(copy).to_have_accessible_name(
        "Copy failed. Select the code and copy it manually."
    )
    expect(copy).to_have_text("Copy", timeout=4000)


def test_touch_toolbars_remain_visible_while_long_code_scrolls_independently(
    browser: Browser, base_url: str
) -> None:
    context = browser.new_context(
        base_url=base_url,
        viewport={"width": 320, "height": 844},
        is_mobile=True,
        has_touch=True,
    )
    try:
        page = context.new_page()
        page.goto(ARTICLE)
        expect(page.locator(".workspace")).to_be_visible()
        block = page.locator(".code-block").first
        copy = block.locator(".code-copy")
        expect(copy).to_have_css("opacity", "1")
        block.scroll_into_view_if_needed()
        position = bounds(copy)
        block.locator("pre").evaluate(r"""(node) => {
          node.scrollLeft = node.scrollWidth;
        }""")
        assert bounds(copy)["x"] == position["x"]
        assert (
            page.evaluate("() => document.documentElement.scrollWidth <= innerWidth")
            is True
        )
        page.screenshot(path="test-results/code-toolbar-mobile.png")
    finally:
        context.close()


def test_static_articles_keep_language_labels_without_showing_inactive_copy_buttons(
    browser: Browser, base_url: str
) -> None:
    context = browser.new_context(base_url=base_url, java_script_enabled=False)
    try:
        page = context.new_page()
        page.goto(ARTICLE)
        expect(page.locator(".code-language")).to_have_text(["haskell", "elm"])
        for copy in page.locator(".code-copy").all():
            expect(copy).to_be_hidden()
        expect(page.locator("pre code").first).to_be_visible()
    finally:
        context.close()
