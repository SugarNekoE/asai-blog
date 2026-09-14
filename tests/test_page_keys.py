import re

from playwright.sync_api import Page, expect

from tests.helpers import attribute, query_param, query_params


def test_elm_hint_geometry_clips_viewport_edges_and_excludes_hidden_or_covered_targets(
    page: Page,
) -> None:
    page.set_viewport_size({"width": 1440, "height": 900})
    page.goto("/")
    expect(page.locator(".workspace")).to_be_visible()
    page.evaluate(r"""() => {
      const fixture = document.createElement('div');
      fixture.style.cssText = 'position:fixed;inset:0;z-index:100;pointer-events:none';
      for (const [name, left, top, extra] of [
        ['Edge left', -20, 100, ''],
        ['Edge bottom', 1420, 890, ''],
        ['Transparent', 500, 100, 'opacity:0'],
        ['Covered', 700, 100, ''],
        ['Disabled', 900, 100, ''],
      ]) {
        const link = document.createElement('a');
        link.href = '/?fixture=' + name;
        link.dataset.linkHint = name;
        link.setAttribute('aria-label', 'Alternative name');
        link.textContent = name;
        link.style.cssText = `position:absolute;left:${left}px;top:${top}px;width:100px;height:40px;pointer-events:auto;${extra}`;
        if (name === 'Disabled') link.setAttribute('aria-disabled', 'true');
        fixture.append(link);
      }
      const cover = document.createElement('div');
      cover.style.cssText =
        'position:absolute;left:700px;top:100px;width:100px;height:40px;background:black;pointer-events:auto';
      fixture.append(cover);
      document.body.append(fixture);
    }""")
    page.keyboard.press("f")
    left = page.locator('.link-hint[title="Edge left"]')
    bottom = page.locator('.link-hint[title="Edge bottom"]')
    expect(left).to_be_visible()
    expect(left).to_have_css("left", "4px")
    expect(bottom).to_have_css("left", "1400px")
    expect(bottom).to_have_css("top", "876px")
    for name in ["Transparent", "Covered", "Disabled", "Alternative name"]:
        expect(page.locator(f'.link-hint[title="{name}"]')).to_have_count(0)
    key = attribute(left, "data-hint")
    page.keyboard.type(key)
    expect(page).to_have_url(re.compile("fixture=Edge%20left"))


def test_mouse_focused_categories_and_page_size_controls_do_not_gain_tab_outlines_from_shortcuts(
    page: Page,
) -> None:
    page.goto("/")
    expect(page.locator(".workspace")).to_be_visible()
    category = page.get_by_role("button", name=re.compile("^programming\\b"))
    page.keyboard.press("Tab")
    category.focus()
    expect(category).to_have_css("outline-style", "solid")
    category.click()
    expect(category).to_be_focused()
    expect(category).to_have_css("outline-style", "none")
    page.keyboard.press("f")
    expect(page.locator(".link-hints")).to_be_visible()
    expect(category).to_be_focused()
    expect(category).to_have_css("outline-style", "none")
    page.keyboard.press("Escape")
    expect(page.locator(".link-hints")).to_have_count(0)
    size = page.get_by_label("Notes per page")
    size.click()
    page.keyboard.press("Escape")
    expect(size).to_have_css("outline-style", "none")
    size.select_option("30")
    expect(page.locator("#notebook-heading")).to_be_focused()
    expect(page.locator("#notebook-heading")).to_have_css("outline-style", "none")
    page.keyboard.press("Tab")
    size.focus()
    expect(size).to_have_css("outline-style", "solid")
    page.keyboard.press("Escape")
    expect(size).not_to_be_focused()
    expect(page.locator("[data-tab-focus]")).to_have_count(0)


def test_tab_shows_focus_when_a_dialog_traps_focus_on_the_same_mouse_focused_button(
    page: Page,
) -> None:
    page.goto("/")
    page.get_by_role("button", name="Keyboard shortcuts", exact=True).click()
    dialog = page.locator("#keymap-dialog")
    close = dialog.get_by_role("button", name="Close keyboard shortcuts", exact=True)
    expect(close).to_be_focused()
    expect(close).to_have_css("outline-style", "none")
    page.keyboard.press("Tab")
    expect(close).to_be_focused()
    expect(close).to_have_css("outline-style", "solid")
    dialog.locator("#keymap-title").click()
    page.keyboard.press("ArrowDown")
    expect(close).to_be_focused()
    expect(close).to_have_css("outline-style", "none")
    expect(dialog).to_have_css("outline-style", "none")
    page.keyboard.press("Shift+Tab")
    expect(close).to_have_css("outline-style", "solid")


def test_elm_assigns_unambiguous_hint_labels_across_the_three_letter_boundary(
    page: Page,
) -> None:
    page.goto("/")
    expect(page.locator(".workspace")).to_be_visible()
    page.evaluate(r"""() => {
      const links = document.createElement('nav');
      links.setAttribute('aria-label', 'Hint fixture');
      Object.assign(links.style, {
        position: 'fixed',
        inset: '80px 20px auto 270px',
        zIndex: '10',
        display: 'grid',
        gridTemplateColumns: 'repeat(10, 1fr)',
      });
      for (let index = 0; index < 100; index++) {
        const link = document.createElement('a');
        link.href = `/?target=${index}`;
        link.textContent = `Target ${index}`;
        link.style.padding = '4px';
        links.append(link);
      }
      document.body.append(links);
    }""")
    page.keyboard.press("f")
    target = page.locator('.link-hint[title="Target 99"]')
    expect(target).to_be_visible()
    labels = page.locator(".link-hint").evaluate_all(
        "(nodes) => nodes.map((node) => node.dataset.hint)"
    )
    assert len(labels) > 81
    assert len(set(labels)) == len(labels)
    assert all(len(label) == 3 for label in labels) is True
    key = attribute(target, "data-hint")
    page.keyboard.type(key[0:2])
    expect(page).to_have_url("/")
    page.keyboard.type(key[2:])
    expect(page).to_have_url("/?target=99")


def test_note_highlighting_follows_only_its_own_row_and_clears_when_the_pointer_leaves(
    page: Page,
) -> None:
    page.set_viewport_size({"width": 1440, "height": 1000})
    page.goto("/")
    expect(page.locator(".workspace")).to_be_visible()
    rows = page.locator(".post-row")
    titles = rows.locator("h3 a")
    normal = page.locator("body").evaluate("(node) => getComputedStyle(node).color")
    accent = page.locator(".brand-mark").evaluate(
        "(node) => getComputedStyle(node).color"
    )
    page.locator(".intro h1").hover()
    for title in titles.all():
        expect(title).to_have_css("color", normal)
    rows.first.locator("p").hover()
    expect(titles.first).to_have_css("color", accent)
    expect(titles.nth(1)).to_have_css("color", normal)
    rows.nth(1).locator("p").hover()
    expect(titles.first).to_have_css("color", normal)
    expect(titles.nth(1)).to_have_css("color", accent)
    page.locator(".intro h1").hover()
    for title in titles.all():
        expect(title).to_have_css("color", normal)
    page.mouse.move(1, 1)
    page.keyboard.press("Tab")
    titles.first.focus()
    expect(titles.first).to_have_css("color", accent)
    titles.first.press("Escape")
    expect(titles.first).to_have_css("color", normal)


def test_escape_clears_control_outlines_and_input_focus_without_changing_page_state(
    page: Page,
) -> None:
    page.goto("/?tag=haskell")
    expect(page.locator(".workspace")).to_be_visible()
    page.keyboard.press("Tab")
    theme = page.get_by_role("button", name="Toggle color theme", exact=True)
    theme.focus()
    expect(theme).to_have_css("outline-style", "solid")
    theme.press("Escape")
    expect(theme).not_to_be_focused()
    expect(theme).to_have_css("outline-style", "none")
    expect(page.locator("html")).to_have_attribute("data-theme", "dark")
    page.keyboard.press("Tab")
    expect(page.locator(":focus-visible")).to_have_css("outline-style", "solid")
    inline = page.get_by_role("searchbox")
    inline.fill("plain")
    expect(page).to_have_url(re.compile("q=plain"))
    url = page.url
    inline.press("Escape")
    expect(inline).not_to_be_focused()
    expect(inline).to_have_value("plain")
    expect(page.locator(".selected-tag")).to_have_count(1)
    expect(page).to_have_url(url)
    note = page.locator(".post-row").first.get_by_role("link")
    note.focus()
    note.press("Escape")
    expect(note).not_to_be_focused()
    expect(page).to_have_url(url)


def test_escape_closes_panels_and_hints_before_clearing_focus_including_immersive_controls(
    page: Page,
) -> None:
    page.goto("/posts/plain-text-to-a-small-web/")
    expect(page.locator(".workspace")).to_be_visible()
    launcher = page.get_by_role("button", name=re.compile("Search notes"))
    launcher.click()
    expect(page.locator("#launcher-search")).to_be_focused()
    page.keyboard.press("Escape")
    expect(page.locator("#search-dialog")).not_to_be_visible()
    expect(launcher).to_be_focused()
    page.keyboard.press("Escape")
    expect(launcher).not_to_be_focused()
    launcher.focus()
    page.keyboard.press("f")
    expect(page.locator(".link-hint").first).to_be_visible()
    page.keyboard.press("Escape")
    expect(page.locator(".link-hints")).to_have_count(0)
    expect(launcher).to_be_focused()
    page.keyboard.press("Escape")
    expect(launcher).not_to_be_focused()
    page.keyboard.press("Shift+I")
    exit_button = page.get_by_role("button", name="Exit immersive mode", exact=True)
    exit_button.focus()
    exit_button.press("Escape")
    expect(exit_button).not_to_be_focused()
    expect(exit_button).to_have_css("outline-style", "none")
    expect(page.locator(".workspace")).to_have_class(re.compile("is-immersive"))
    copy = page.locator(".code-copy").first
    copy.focus()
    copy.press("Escape")
    expect(copy).not_to_be_focused()
    expect(copy).to_have_css("outline-style", "none")


def test_enter_opens_the_selected_index_note_without_hijacking_native_controls(
    page: Page,
) -> None:
    page.goto("/")
    expect(page.locator(".post-row.is-selected")).to_contain_text("From plain text")
    page.locator(".post-row").nth(1).hover()
    expect(page.locator(".post-row.is-selected")).to_contain_text("Types are a way")
    page.keyboard.press("Enter")
    expect(page).to_have_url(
        re.compile("\\/posts\\/types-as-design-tools\\/index.html$")
    )
    page.goto("/?tag=notes")
    expect(page.locator(".post-row.is-selected")).to_contain_text(
        "A notebook that stays yours"
    )
    page.keyboard.press("Enter")
    expect(page).to_have_url(
        re.compile("\\/posts\\/a-notebook-that-stays-yours\\/index.html$")
    )
    page.goto("/")
    theme = page.get_by_role("button", name="Toggle color theme", exact=True)
    theme.focus()
    theme.press("Enter")
    expect(page.locator("html")).to_have_attribute("data-theme", "light")
    expect(page).to_have_url("/")
    title = page.locator(".post-row").last.get_by_role("link")
    title.focus()
    expect(page.locator(".post-row.is-selected")).to_contain_text("A quieter interface")
    title.press("Enter")
    expect(page).to_have_url(re.compile("\\/posts\\/a-quieter-interface\\/index.html$"))
    page.goto("/?q=unfindable")
    expect(page.locator(".post-row")).to_have_count(0)
    page.keyboard.press("Enter")
    expect(page).to_have_url(re.compile("\\?q=unfindable$"))


def test_page_keys_do_not_interrupt_typing_or_the_search_launcher(page: Page) -> None:
    page.goto("/")
    inline = page.get_by_role("searchbox")
    inline.fill("")
    inline.press("t")
    inline.press("o")
    inline.press("f")
    expect(inline).to_have_value("tof")
    expect(page.locator("html")).to_have_attribute("data-theme", "dark")
    expect(page.locator(".link-hints")).to_have_count(0)
    inline.press("Enter")
    expect(page).to_have_url(re.compile("q=tof"))
    page.locator(".search-launch").click()
    search = page.get_by_role("combobox", name="Search all notes", exact=True)
    search.fill("")
    search.press("t")
    search.press("o")
    search.press("f")
    expect(search).to_have_value("tof")
    expect(page.locator("html")).to_have_attribute("data-theme", "dark")
    expect(page.locator(".link-hints")).to_have_count(0)


def test_f_displays_prefix_free_link_hints_and_follows_a_chosen_visible_link(
    page: Page,
) -> None:
    page.set_viewport_size({"width": 1440, "height": 900})
    page.goto("/posts/plain-text-to-a-small-web/")
    expect(page.locator(".workspace")).to_be_visible()
    page.evaluate("() => document.fonts.ready")
    page.keyboard.press("f")
    expect(page.locator(".link-hint").first).to_be_visible()
    labels = page.locator(".link-hint").evaluate_all(
        "(nodes) => nodes.map((node) => node.dataset.hint)"
    )
    assert len(set(labels)) == len(labels)
    assert len(set([len(label) for label in labels])) == 1
    assert len(labels) > 9
    category_hint = page.locator('.link-hint[title="web"]')
    key = attribute(category_hint, "data-hint")
    page.screenshot(path="test-results/link-hints-desktop.png")
    page.keyboard.press("t")
    expect(page.locator(".link-hint")).to_have_count(0)
    expect(page.locator(".link-hint-status")).to_contain_text("No matching hints")
    expect(page.locator("html")).to_have_attribute("data-theme", "dark")
    page.keyboard.press("Backspace")
    expect(page.locator(".link-hint")).to_have_count(len(labels))
    page.keyboard.type(key[0])
    expect(page).to_have_url(re.compile("\\/posts\\/plain-text-to-a-small-web\\/$"))
    expect(page.locator(".link-hint-status")).to_contain_text(
        f"Open link: {key[0].upper()}"
    )
    narrowed = page.locator(".link-hint").evaluate_all(
        "(nodes) => nodes.map((node) => node.dataset.hint)"
    )
    assert all(label.startswith(key[0]) for label in narrowed) is True
    page.keyboard.type(key[1:])
    expect(page).to_have_url(re.compile("\\?category=web$"))
    expect(page.locator(".post-row")).to_have_count(2)


def test_hint_mode_cancels_on_escape_and_viewport_changes(page: Page) -> None:
    page.set_viewport_size({"width": 1440, "height": 900})
    page.goto("/posts/plain-text-to-a-small-web/")
    expect(page.locator(".workspace")).to_be_visible()
    page.keyboard.press("f")
    expect(page.locator(".link-hint").first).to_be_visible()
    page.keyboard.press("Escape")
    expect(page.locator(".link-hints")).to_have_count(0)
    page.keyboard.press("f")
    expect(page.locator(".link-hint").first).to_be_visible()
    page.evaluate("() => window.scrollBy(0, 100)")
    expect(page.locator(".link-hints")).to_have_count(0)
    page.keyboard.press("f")
    expect(page.locator(".link-hint").first).to_be_visible()
    page.set_viewport_size({"width": 1280, "height": 900})
    expect(page.locator(".link-hints")).to_have_count(0)
    page.keyboard.press("?")
    expect(
        page.get_by_role("dialog", name="Keyboard shortcuts", exact=True)
    ).to_be_visible()
    page.keyboard.press("f")
    expect(page.locator(".link-hints")).to_have_count(0)


def test_index_category_buttons_are_hint_targets_and_preserve_tag_filters(
    page: Page,
) -> None:
    page.set_viewport_size({"width": 1440, "height": 900})
    page.goto("/?tag=haskell")
    expect(page.locator(".post-row")).to_have_count(2)
    page.keyboard.press("f")
    for category in ["notes", "programming", "web"]:
        expect(page.locator(f'.link-hint[title="{category}"]')).to_be_visible()
    key = attribute(page.locator('.link-hint[title="programming"]'), "data-hint")
    page.keyboard.type(key)
    expect(page.locator(".link-hints")).to_have_count(0)
    expect(page.locator(".breadcrumbs .current-category")).to_have_text("programming")
    expect(page.locator(".post-row")).to_have_count(1)
    expect(page.locator(".post-row")).to_contain_text(
        "Types are a way to ask better questions"
    )
    assert query_param(page.url, "category") == "programming"
    assert query_params(page.url).get("tag", []) == ["haskell"]
    page.keyboard.press("f")
    next = attribute(page.locator('.link-hint[title="web"]'), "data-hint")
    page.keyboard.type(next)
    expect(page.locator(".breadcrumbs .current-category")).to_have_text("web")
    expect(page.locator(".post-row")).to_contain_text(
        "From plain text to a small, personal web"
    )
