import re

from playwright.sync_api import Page, expect

from tests.helpers import bounds


def test_shift_i_widens_the_article_hides_surrounding_panels_and_restores_them(
    page: Page,
) -> None:
    page.set_viewport_size({"width": 1920, "height": 900})
    page.goto("/posts/plain-text-to-a-small-web/")
    expect(page.locator(".workspace")).to_be_visible()
    normal_width = bounds(page.locator(".prose"))["width"]
    page.keyboard.press("i")
    expect(page.locator(".workspace")).not_to_have_class(re.compile("is-immersive"))
    page.keyboard.press("Shift+I")
    expect(page.locator(".workspace")).to_have_class(re.compile("is-immersive"))
    immersive_header = page.locator(".immersive-header")
    expect(
        immersive_header.get_by_role("link", name="Asai Blog", exact=True)
    ).to_have_attribute("href", "/")
    expect(immersive_header.locator(".brand-mark")).to_have_text("λ")
    expect(immersive_header.get_by_text("Immersive Mode", exact=True)).to_be_visible()
    expect(
        immersive_header.get_by_role("button", name="Exit immersive mode")
    ).to_contain_text("Shift + I")
    expect(page.locator("#main")).to_be_focused()
    expect(page.locator("#main")).to_have_css("outline-style", "none")
    page.locator(".prose h1").click()
    expect(page.locator("#main")).to_have_css("outline-style", "none")
    for selector in [".sidebar", ".topbar", ".statusbar", ".prose > .back"]:
        expect(page.locator(selector)).to_be_hidden()
    expect(page.locator(".page-outline")).to_have_count(0)
    expect(page.locator(".reading-layout")).to_have_count(0)
    assert bounds(page.locator(".prose"))["width"] > normal_width + 100
    assert (
        page.evaluate("() => document.documentElement.scrollWidth <= innerWidth")
        is True
    )
    page.screenshot(path="test-results/immersive-desktop.png")
    page.keyboard.press("o")
    expect(page.locator(".page-outline")).to_have_count(0)
    page.keyboard.press("Shift+I")
    expect(page.locator(".workspace")).not_to_have_class(re.compile("is-immersive"))
    expect(immersive_header).to_have_count(0)
    for selector in [
        ".sidebar",
        ".topbar",
        ".statusbar",
        ".page-outline",
        ".prose > .back",
    ]:
        expect(page.locator(selector)).to_be_visible()
    assert bounds(page.locator(".prose"))["width"] == normal_width


def test_immersive_header_stays_reachable_on_narrow_screens_and_exits_with_a_click(
    page: Page,
) -> None:
    page.goto("/posts/plain-text-to-a-small-web/")
    expect(page.locator(".workspace")).to_be_visible()
    page.keyboard.press("Shift+I")
    exit_button = page.get_by_role("button", name="Exit immersive mode", exact=True)
    for width in [390, 320]:
        page.set_viewport_size({"width": width, "height": 844})
        expect(exit_button).to_be_in_viewport()
        expect(page.locator(".immersive-brand")).to_be_in_viewport()
        assert (
            page.evaluate("() => document.documentElement.scrollWidth <= innerWidth")
            is True
        )
    page.evaluate("() => window.scrollTo({ top: 700, behavior: 'instant' })")
    expect(exit_button).to_be_in_viewport()
    heading = page.locator(".prose h2[id]").first
    heading.evaluate(
        "(node) => node.scrollIntoView({ behavior: 'instant', block: 'start' })"
    )
    header_box = bounds(page.locator(".immersive-header"))
    assert bounds(heading)["y"] >= header_box["y"] + header_box["height"]
    page.keyboard.press("Tab")
    exit_button.focus()
    expect(exit_button).to_have_css("outline-style", "solid")
    page.screenshot(path="test-results/immersive-header-mobile.png")
    exit_button.click()
    expect(page.locator(".workspace")).not_to_have_class(re.compile("is-immersive"))
    expect(page.locator(".immersive-header")).to_have_count(0)
    expect(page.locator("#main")).to_be_focused()
    expect(page.locator("#main")).to_have_css("outline-style", "none")


def test_immersive_toggling_closes_existing_panels_and_hints_while_explicit_search_remains_usable(
    page: Page,
) -> None:
    page.goto("/posts/plain-text-to-a-small-web/")
    expect(page.locator(".workspace")).to_be_visible()
    page.keyboard.press("f")
    expect(page.locator(".link-hint").first).to_be_visible()
    page.keyboard.press("Shift+I")
    expect(page.locator(".workspace")).to_have_class(re.compile("is-immersive"))
    expect(page.locator(".link-hints")).to_have_count(0)
    expect(page.locator("#main")).to_be_focused()
    page.keyboard.press("/")
    search = page.get_by_role("combobox", name="Search all notes", exact=True)
    expect(search).to_be_focused()
    search.press("Shift+I")
    expect(search).to_have_value("I")
    expect(page.locator(".workspace")).to_have_class(re.compile("is-immersive"))
    page.keyboard.press("Escape")
    expect(search).not_to_be_visible()
    expect(page.locator("#main")).to_be_focused()
    page.keyboard.press("?")
    keymap = page.get_by_role("dialog", name="Keyboard shortcuts", exact=True)
    expect(keymap).to_be_visible()
    expect(
        keymap.get_by_text("Toggle Immersive Mode on a note", exact=True)
    ).to_be_visible()
    page.keyboard.press("Shift+I")
    expect(keymap).not_to_be_visible()
    expect(page.locator(".workspace")).not_to_have_class(re.compile("is-immersive"))
    expect(page.locator("html")).not_to_have_class(re.compile("search-open"))
    page.keyboard.press("?")
    expect(keymap).to_be_visible()
    page.keyboard.press("Shift+I")
    expect(keymap).not_to_be_visible()
    expect(page.locator(".workspace")).to_have_class(re.compile("is-immersive"))


def test_immersive_mode_preserves_the_note_outline_and_stays_disabled_on_filtered_indexes(
    page: Page,
) -> None:
    page.set_viewport_size({"width": 1920, "height": 900})
    page.goto("/posts/plain-text-to-a-small-web/")
    expect(page.locator(".workspace")).to_be_visible()
    page.keyboard.press("o")
    expect(page.locator(".page-outline")).to_have_count(0)
    page.keyboard.press("Shift+I")
    expect(page.locator(".workspace")).to_have_class(re.compile("is-immersive"))
    page.keyboard.press("Shift+I")
    expect(page.locator(".workspace")).not_to_have_class(re.compile("is-immersive"))
    expect(page.locator(".page-outline")).to_have_count(0)
    page.goto("/?category=web&tag=elm&perPage=30")
    inline = page.get_by_role("searchbox")
    inline.focus()
    inline.press("Shift+I")
    expect(inline).to_have_value("I")
    expect(page.locator(".workspace")).not_to_have_class(re.compile("is-immersive"))
    expect(page).to_have_url(re.compile("q=I"))
    url = page.url
    inline.evaluate("(node) => node.blur()")
    page.keyboard.press("Shift+I")
    expect(page.locator(".workspace")).not_to_have_class(re.compile("is-immersive"))
    expect(page.locator(".immersive-header")).to_have_count(0)
    expect(page.locator(".topbar")).to_be_visible()
    page.set_viewport_size({"width": 390, "height": 844})
    page.keyboard.press("Shift+I")
    expect(page.locator(".workspace")).not_to_have_class(re.compile("is-immersive"))
    expect(inline).to_have_value("I")
    expect(page.locator(".breadcrumbs .current-category")).to_have_text("web")
    expect(page.locator(".selected-tag")).to_have_count(1)
    expect(page.get_by_label("Notes per page")).to_have_value("30")
    expect(page).to_have_url(url)


def test_index_and_error_pages_ignore_immersive_shortcuts_while_panels_and_hints_are_open(
    page: Page,
) -> None:
    for path in ["/", "/?category=web", "/404.html"]:
        page.goto(path)
        expect(page.locator(".workspace")).to_be_visible()
        page.keyboard.press("Shift+I")
        expect(page.locator(".workspace")).not_to_have_class(re.compile("is-immersive"))
        page.keyboard.press("?")
        keymap = page.locator("#keymap-dialog")
        expect(keymap).to_be_visible()
        page.keyboard.press("Shift+I")
        expect(keymap).to_be_visible()
        expect(page.locator(".workspace")).not_to_have_class(re.compile("is-immersive"))
        page.keyboard.press("Escape")
        expect(keymap).not_to_be_visible()
        page.keyboard.press("f")
        expect(page.locator(".link-hints")).to_be_visible()
        page.keyboard.press("Shift+I")
        expect(page.locator(".link-hints")).to_be_visible()
        expect(page.locator(".workspace")).not_to_have_class(re.compile("is-immersive"))
        expect(page.locator(".immersive-header")).to_have_count(0)
        page.keyboard.press("Escape")
        expect(page).to_have_url(path)
