import re

from playwright.sync_api import Page, expect

from tests.helpers import bounds


def test_opening_search_again_resets_its_query_and_focuses_the_input(
    page: Page,
) -> None:
    page.goto("/")
    expect(page.locator(".workspace")).to_be_visible()
    page.keyboard.press("/")
    dialog = page.locator("#search-dialog")
    search = dialog.get_by_role("combobox")
    search.fill("compiler")
    dialog.get_by_role("button", name="Close search", exact=True).focus()
    page.keyboard.press("/")
    expect(search).to_be_focused()
    expect(search).to_have_value("")
    expect(dialog.get_by_role("option")).to_have_count(4)


def test_search_navigation_survives_pointer_selection_and_keeps_focus_off_panel_containers(
    page: Page,
) -> None:
    page.goto("/")
    expect(page.locator(".workspace")).to_be_visible()
    page.keyboard.press("/")
    dialog = page.locator("#search-dialog")
    search = dialog.get_by_role("combobox")
    results = dialog.get_by_role("option")
    expect(search).to_be_focused()
    dialog.locator("#search-dialog-title").click()
    expect(search).to_be_focused()
    results.nth(1).hover()
    expect(results.nth(1)).to_have_attribute("aria-selected", "true")
    for index in [2, 3, 0]:
        page.keyboard.press("ArrowDown")
        expect(results.nth(index)).to_have_attribute("aria-selected", "true")
        expect(search).to_be_focused()
        expect(dialog).not_to_be_focused()
        expect(dialog).to_have_css("outline-style", "none")
    page.mouse.move(0, 0)
    results.nth(2).focus()
    expect(results.nth(2)).to_have_attribute("aria-selected", "true")
    page.keyboard.press("ArrowUp")
    expect(results.nth(1)).to_have_attribute("aria-selected", "true")
    expect(search).to_be_focused()
    dialog.locator(".launcher-results").evaluate("(node) => node.focus()")
    expect(search).to_be_focused()
    page.keyboard.press("Enter")
    expect(page).to_have_url(
        re.compile("\\/posts\\/types-as-design-tools\\/index.html$")
    )


def test_keymap_containers_never_keep_focus_and_native_close_button_keys_still_work(
    page: Page,
) -> None:
    page.goto("/")
    expect(page.locator(".workspace")).to_be_visible()
    page.keyboard.press("?")
    dialog = page.locator("#keymap-dialog")
    close = dialog.get_by_role("button", name="Close keyboard shortcuts", exact=True)
    expect(close).to_be_focused()
    dialog.locator("#keymap-title").click()
    expect(close).to_be_focused()
    dialog.locator(".keymap-row dd").first.click()
    expect(close).to_be_focused()
    for key in ["ArrowDown", "ArrowUp", "Tab", "Shift+Tab"]:
        page.keyboard.press(key)
        expect(close).to_be_focused()
        expect(dialog).not_to_be_focused()
        expect(dialog).to_have_css("outline-style", "none")
    dialog.evaluate("(node) => node.focus()")
    expect(close).to_be_focused()
    close.press("Enter")
    expect(dialog).not_to_be_visible()
    page.keyboard.press("/")
    search_dialog = page.locator("#search-dialog")
    close_search = search_dialog.get_by_role("button", name="Close search", exact=True)
    close_search.focus()
    close_search.press("Enter")
    expect(search_dialog).not_to_be_visible()
    expect(page).to_have_url("/")


def test_search_launcher_finds_title_description_words_tags_categories_and_combinations(
    page: Page,
) -> None:
    page.goto("/?tag=notes")
    expect(page.locator(".post-row")).to_have_count(2)
    page.locator(".search-launch").click()
    dialog = page.get_by_role("dialog", name="Search notes", exact=True)
    search = dialog.get_by_role("combobox", name="Search all notes", exact=True)
    results = dialog.get_by_role("option")
    expect(search).to_be_focused()
    expect(results).to_have_count(4)
    cases: list[tuple[str, int, str]] = [
        ("TYPES", 1, "Types are a way to ask better questions"),
        ("algebraic", 1, "Types are a way to ask better questions"),
        ("#HAS", 2, ""),
        ("#haskell #elm", 1, "From plain text to a small, personal web"),
        ("/prog", 1, "Types are a way to ask better questions"),
        ("/web #elm compiler", 1, "From plain text to a small, personal web"),
        ("/notes", 1, "A notebook that stays yours"),
        ("#", 4, ""),
        ("/", 4, ""),
        ("RefreshFailed", 0, ""),
        ("#unknown", 0, ""),
    ]
    for query, count, title in cases:
        search.fill(query)
        expect(results).to_have_count(count)
        if title:
            expect(results.first).to_contain_text(title)
    expect(dialog.get_by_text("No notes match.", exact=False)).to_be_visible()
    search.fill("#haskell")
    page.screenshot(path="test-results/search-launcher-desktop.png")
    page.keyboard.press("Escape")
    expect(dialog).not_to_be_visible()
    expect(page.locator(".post-row")).to_have_count(2)
    expect(page).to_have_url(re.compile("\\?tag=notes$"))


def test_launcher_is_modal_darkens_the_background_traps_focus_and_restores_it_on_dismissal(
    page: Page,
) -> None:
    page.goto("/")
    opener = page.locator(".search-launch")
    opener.click()
    dialog = page.locator("#search-dialog")
    expect(dialog).to_be_visible()
    assert dialog.evaluate("(node) => node.matches(':modal')") is True
    assert (
        dialog.evaluate(
            "(node) => getComputedStyle(node, '::backdrop').backgroundColor"
        )
        == "rgba(0, 0, 0, 0.7)"
    )
    expect(page.locator("html")).to_have_css("overflow", "hidden")
    for _step in range(5):
        page.keyboard.press("Tab")
        assert (
            page.evaluate(
                "() => Boolean(document.activeElement.closest('#search-dialog'))"
            )
            is True
        )
    page.keyboard.press("Escape")
    expect(dialog).not_to_be_visible()
    expect(opener).to_be_focused()
    expect(page.locator("html")).not_to_have_class(re.compile("search-open"))
    opener.click()
    expect(dialog).to_be_visible()
    page.mouse.click(8, 8)
    expect(dialog).not_to_be_visible()
    expect(opener).to_be_focused()
    opener.click()
    dialog.get_by_role("button", name="Close search", exact=True).click()
    expect(dialog).not_to_be_visible()


def test_launcher_opens_on_article_pages_and_supports_arrow_keys_and_enter(
    page: Page,
) -> None:
    page.goto("/posts/a-notebook-that-stays-yours/")
    expect(page.locator(".workspace")).to_be_visible()
    page.keyboard.press("/")
    dialog = page.locator("#search-dialog")
    expect(dialog).to_be_visible()
    expect(page).to_have_url(re.compile("\\/posts\\/a-notebook-that-stays-yours\\/$"))
    search = dialog.get_by_role("combobox")
    expect(search).to_be_focused()
    search.fill("/web")
    expect(dialog.get_by_role("option")).to_have_count(2)
    search.press("ArrowDown")
    expect(search).to_have_attribute("aria-activedescendant", "search-result-1")
    expect(dialog.get_by_role("option").nth(1)).to_have_attribute(
        "aria-selected", "true"
    )
    search.press("ArrowDown")
    expect(search).to_have_attribute("aria-activedescendant", "search-result-0")
    search.press("ArrowUp")
    expect(search).to_have_attribute("aria-activedescendant", "search-result-1")
    search.press("Enter")
    expect(page).to_have_url(re.compile("\\/posts\\/a-quieter-interface\\/index.html$"))
    expect(page.locator("blog-content h1")).to_have_text(
        "A quieter interface for a noisier web"
    )
    page.locator(".search-launch").click()
    dialog.get_by_role("combobox").fill("#elm")
    dialog.get_by_role("option").click()
    expect(page).to_have_url(
        re.compile("\\/posts\\/plain-text-to-a-small-web\\/index.html$")
    )


def test_launcher_works_on_mobile_and_opens_from_a_direct_search_url(
    page: Page,
) -> None:
    page.set_viewport_size({"width": 390, "height": 844})
    page.goto("/?search=1")
    dialog = page.locator("#search-dialog")
    expect(dialog).to_be_visible()
    expect(dialog.get_by_role("combobox")).to_be_focused()
    box = bounds(dialog)
    assert box["x"] >= 0
    assert box["x"] + box["width"] <= 390
    assert box["y"] + box["height"] <= 844
    dialog.get_by_role("combobox").fill("/web")
    expect(dialog.get_by_role("option")).to_have_count(2)
    page.screenshot(path="test-results/search-launcher-mobile.png")
    page.keyboard.press("Escape")
    page.get_by_role("button", name="Toggle navigation").click()
    page.locator(".search-launch").click()
    expect(dialog).to_be_visible()
    expect(page.locator(".sidebar")).to_be_hidden()
    page.keyboard.press("Escape")
    expect(page.get_by_role("button", name="Toggle navigation")).to_be_focused()
    page.keyboard.press("/")
    expect(dialog).to_be_visible()


def test_question_mark_opens_the_keymap_and_slash_switches_exclusively_to_search(
    page: Page,
) -> None:
    page.goto("/posts/types-as-design-tools/")
    expect(page.locator(".workspace")).to_be_visible()
    sidebar_links = bounds(page.locator(".sidebar-links"))
    help_button = bounds(page.locator(".sidebar-bottom .keymap-trigger"))
    assert help_button["x"] > sidebar_links["x"] + sidebar_links["width"]
    assert (
        abs(
            help_button["y"]
            + help_button["height"] / 2
            - sidebar_links["y"]
            - sidebar_links["height"] / 2
        )
        < 1
    )
    expect(page.locator(".statusbar .keymap-trigger")).to_have_count(0)
    page.keyboard.press("?")
    keymap = page.get_by_role("dialog", name="Keyboard shortcuts", exact=True)
    search = page.get_by_role("dialog", name="Search notes", exact=True)
    expect(keymap).to_be_visible()
    expect(keymap.locator("kbd").filter(has_text=re.compile("^\\?$"))).to_have_count(1)
    expect(keymap.locator("kbd").filter(has_text=re.compile("^\\/$"))).to_have_count(1)
    expect(page.locator("dialog:modal")).to_have_count(1)
    for _index in range(4):
        page.keyboard.press("Tab")
        assert (
            page.evaluate(
                "() => Boolean(document.activeElement.closest('#keymap-dialog'))"
            )
            is True
        )
    page.keyboard.press("/")
    expect(keymap).not_to_be_visible()
    expect(search).to_be_visible()
    expect(search.get_by_role("combobox")).to_be_focused()
    expect(page.locator("dialog:modal")).to_have_count(1)
    search.get_by_role("combobox").press("?")
    expect(search.get_by_role("combobox")).to_have_value("?")
    expect(keymap).not_to_be_visible()
    page.keyboard.press("Escape")
    expect(page.locator("dialog:modal")).to_have_count(0)
    page.keyboard.press("?")
    expect(keymap).to_be_visible()
    page.keyboard.press("Escape")
    expect(keymap).not_to_be_visible()
    expect(page).to_have_url(re.compile("\\/posts\\/types-as-design-tools\\/$"))


def test_keymap_is_available_on_mobile_and_typing_question_marks_leaves_text_fields_alone(
    page: Page,
) -> None:
    page.set_viewport_size({"width": 390, "height": 844})
    page.goto("/")
    inline_search = page.get_by_role("searchbox")
    inline_search.fill("why")
    inline_search.press("?")
    expect(inline_search).to_have_value("why?")
    expect(page.locator("dialog:modal")).to_have_count(0)
    menu = page.get_by_role("button", name="Toggle navigation", exact=True)
    menu.click()
    opener = page.locator(".sidebar-bottom").get_by_role(
        "button", name="Keyboard shortcuts", exact=True
    )
    opener.click()
    keymap = page.get_by_role("dialog", name="Keyboard shortcuts", exact=True)
    expect(keymap).to_be_visible()
    box = bounds(keymap)
    assert box["x"] >= 0
    assert box["x"] + box["width"] <= 390
    assert box["y"] + box["height"] <= 844
    page.screenshot(path="test-results/keymap-mobile.png")
    page.mouse.click(8, 8)
    expect(keymap).not_to_be_visible()
    expect(menu).to_be_focused()
    expect(page.locator("html")).not_to_have_class(re.compile("search-open"))
    menu.click()
    opener.click()
    expect(
        keymap.get_by_role("button", name="Open search /", exact=True)
    ).to_have_count(0)
    page.keyboard.press("/")
    expect(keymap).not_to_be_visible()
    expect(page.get_by_role("dialog", name="Search notes", exact=True)).to_be_visible()
    page.keyboard.press("Escape")
    expect(menu).to_be_focused()
