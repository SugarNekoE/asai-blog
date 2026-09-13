import re
from datetime import datetime, timedelta
from math import floor
from typing import TypedDict, cast
from urllib.parse import urlsplit

from playwright.sync_api import (
    Browser,
    Locator,
    Page,
    expect,
)

from tests.helpers import (
    bounds,
    content_text,
    hold_requests,
    query_param,
    query_params,
)


def test_index_and_notes_share_content_width_and_alignment_with_or_without_an_outline(
    page: Page,
) -> None:
    for width in [1920, 1600, 1599, 1440, 1280, 1100, 768, 390]:
        page.set_viewport_size({"width": width, "height": 1000})
        page.goto("/")
        expect(page.locator(".workspace")).to_be_visible()
        index = bounds(page.locator(".page-content"))
        intro = bounds(page.locator(".intro"))
        page.locator(".post-row h3 a").first.click()
        expect(page.locator(".workspace")).to_be_visible()
        if width < 1600:
            expect(page.locator(".page-outline")).to_have_count(0)
            page.keyboard.press("o")
        expect(page.locator(".page-outline")).to_be_visible()
        article = bounds(page.locator(".prose"))
        back = bounds(page.locator(".prose > .back"))
        assert abs(index["x"] - article["x"]) < 1
        assert abs(index["width"] - article["width"]) < 1
        assert abs(intro["x"] - back["x"]) < 1
        if width >= 1600:
            assert abs(intro["y"] - back["y"]) < 1
        page.keyboard.press("o")
        expect(page.locator(".page-outline")).to_have_count(0)
        without_outline = bounds(page.locator(".prose"))
        plain_back = bounds(page.locator(".prose > .back"))
        assert abs(index["x"] - without_outline["x"]) < 1
        assert abs(index["width"] - without_outline["width"]) < 1
        assert abs(intro["y"] - plain_back["y"]) < 1
        assert (
            page.evaluate("() => document.documentElement.scrollWidth <= innerWidth")
            is True
        )


def test_notebook_heading_quote_and_controls_share_left_edge(page: Page) -> None:
    for width in [320, 390, 768, 1440, 1599, 1600, 1920]:
        page.set_viewport_size({"width": width, "height": 1000})
        page.goto("/")
        expect(page.locator(".workspace")).to_be_visible()
        content = bounds(page.locator(".page-content"))
        editor = bounds(page.locator(".editor"))
        assert (
            abs(content["x"] + content["width"] / 2 - editor["x"] - editor["width"] / 2)
            < 1
        )
        for selector in [
            ".intro",
            ".intro h1",
            ".intro-quote",
            "#notebook-heading",
            ".filterbar",
            ".search-field",
            ".result-count",
        ]:
            section = page.locator(selector)
            assert abs(bounds(section)["x"] - content["x"]) < 1, selector
            expect(section).to_have_css("position", "static")
        assert (
            page.evaluate("() => document.documentElement.scrollWidth <= innerWidth")
            is True
        )
        page.screenshot(path=f"test-results/notebook-alignment-{width}.png")


def test_tag_picker_dismisses_outside_clicks_and_taps_while_preserving_checkbox_changes(
    browser: Browser, base_url: str
) -> None:
    for touch in [False, True]:
        context = browser.new_context(
            base_url=base_url,
            viewport={"width": (390 if touch else 1440), "height": 900},
            has_touch=touch,
            is_mobile=touch,
        )
        try:
            page = context.new_page()

            def activate(locator: Locator, touch: bool = touch) -> None:
                if touch:
                    locator.tap()
                else:
                    locator.click()

            page.goto("/?category=web")
            expect(page.locator(".workspace")).to_be_visible()
            picker = page.locator(".tag-picker")
            toggle = picker.locator("summary")
            activate(toggle)
            expect(picker).to_have_js_property("open", True)
            for tag in ["haskell", "elm"]:
                checkbox = picker.get_by_role(
                    "checkbox", name=f"Select tag {tag}", exact=True
                )
                activate(checkbox)
                expect(checkbox).to_be_checked()
                expect(picker).to_have_js_property("open", True)
            activate(picker.locator(".filter-mode"))
            expect(picker).to_have_js_property("open", True)
            activate(page.locator(".intro h1"))
            expect(picker).to_have_js_property("open", False)
            expect(page.locator(".selected-tag")).to_have_count(2)
            expect(page.locator(".post-row")).to_have_count(1)
            assert query_param(page.url, "category") == "web"
            assert query_params(page.url).get("tag", []) == ["elm", "haskell"]
            activate(toggle)
            expect(picker).to_have_js_property("open", True)
            activate(page.get_by_role("button", name="Newest first", exact=True))
            expect(picker).to_have_js_property("open", False)
            expect(
                page.get_by_role("button", name="Oldest first", exact=True)
            ).to_be_visible()
            activate(toggle)
            expect(picker).to_have_js_property("open", True)
            activate(toggle)
            expect(picker).to_have_js_property("open", False)
        finally:
            context.close()


def test_search_main_index_tags_sort_empty_state_and_persistent_theme(
    page: Page,
) -> None:
    errors: list[str] = []
    page.on("pageerror", lambda error: errors.append(error.message))
    page.goto("/")
    expect(page.locator(".workspace")).to_be_visible()
    expect(page.locator(".post-row")).to_have_count(4)
    page.get_by_role("searchbox").focus()
    page.get_by_role("searchbox").fill("algebraic")
    expect(page.locator(".post-row")).to_have_count(1)
    expect(page.locator(".post-row")).to_contain_text("Types are a way")
    page.get_by_role("searchbox").fill("unfindable phrase")
    expect(page.get_by_text("No notes on this path. Yet.")).to_be_visible()
    page.get_by_role("button", name="Clear search", exact=True).click()
    add_tag(page, "elm")
    expect(page.locator(".post-row")).to_have_count(1)
    page.get_by_role("button", name="Remove tag elm", exact=True).click()
    page.get_by_role("button", name="Newest first").click()
    expect(page.locator(".post-row").first).to_contain_text("A quieter interface")
    page.get_by_role("button", name="Toggle color theme").click()
    expect(page.locator("html")).to_have_attribute("data-theme", "light")
    page.reload()
    expect(page.locator("html")).to_have_attribute("data-theme", "light")
    assert errors == []
    page.screenshot(path="test-results/notebook-light.png", full_page=True)


def test_article_syntax_highlighting_image_wiki_heading_links_and_history(
    page: Page,
) -> None:
    page.goto("/")
    page.get_by_role("link", name="From plain text to a small, personal web").click()
    expect(page.locator("blog-content h1")).to_contain_text("From plain text")
    expect(page.locator(".sourceCode").first).to_be_visible()
    expect(page.locator(".prose img")).to_be_visible()
    assert (
        page.locator(".prose img").evaluate(
            "(image) => image.complete && image.naturalWidth > 0"
        )
        is True
    )
    page.screenshot(path="test-results/article.png", full_page=True)
    page.get_by_role("link", name="A notebook that stays yours", exact=True).click()
    page.get_by_role("link", name="the publishing pipeline", exact=True).click()
    expect(page).to_have_url(re.compile("#one-source-two-outputs$"))
    expect(page.locator("#one-source-two-outputs")).to_be_in_viewport()
    page.go_back()
    expect(page.locator("h1")).to_contain_text("A notebook that stays yours")


def test_mobile_navigation_and_desktop_layout_fit_the_viewport(page: Page) -> None:
    for width in [390, 768, 1440]:
        page.set_viewport_size({"width": width, "height": 1000})
        page.goto("/")
        expect(page.locator(".workspace")).to_be_visible()
        assert (
            page.evaluate("() => document.documentElement.scrollWidth <= innerWidth")
            is True
        )
        page.screenshot(path=f"test-results/notebook-{width}.png", full_page=True)
    page.set_viewport_size({"width": 390, "height": 844})
    page.get_by_role("button", name="Toggle navigation").click()
    expect(page.locator(".sidebar")).to_be_visible()
    page.get_by_role("navigation", name="Categories", exact=True).get_by_role(
        "button", name="notes"
    ).click()
    expect(page.locator(".sidebar")).to_be_hidden()
    expect(page.locator(".post-row")).to_have_count(1)
    page.get_by_role("button", name="Toggle navigation").click()
    page.locator(".search-launch").click()
    expect(page.locator(".sidebar")).to_be_hidden()
    expect(page.get_by_role("dialog", name="Search notes", exact=True)).to_be_visible()
    expect(
        page.get_by_role("combobox", name="Search all notes", exact=True)
    ).to_be_focused()
    page.keyboard.press("Escape")


def test_static_html_remains_readable_with_javascript_disabled(
    browser: Browser, base_url: str
) -> None:
    context = browser.new_context(base_url=base_url, java_script_enabled=False)
    page = context.new_page()
    page.goto("/")
    expect(page.locator(".fallback nav")).to_contain_text("All Notes")
    expect(page.locator(".post-row")).to_have_count(4)
    page.get_by_role("link", name="From plain text to a small, personal web").click()
    expect(page.locator("h1")).to_contain_text("From plain text")
    expect(page.locator(".fallback nav")).to_contain_text("/ web")
    expect(page.locator("#one-source-two-outputs")).to_be_visible()
    context.close()


def test_unavailable_or_incompatible_json_keeps_the_page_readable(page: Page) -> None:
    page.route("**/api/posts.json", lambda route: route.abort())
    page.goto("/")
    expect(page.locator("#static-content h1")).to_be_visible()
    page.unroute("**/api/posts.json")
    page.route(
        "**/api/posts.json",
        lambda route: route.fulfill(json={"version": 99, "posts": []}),
    )
    page.reload()
    expect(page.locator("#static-content h1")).to_be_visible()
    expect(page.locator(".workspace")).to_have_count(0)
    expect(page.locator(".post-row")).to_have_count(4)


def test_folder_categories_drive_navigation_and_combine_with_main_index_tag_filters(
    page: Page,
) -> None:
    page.goto("/")
    breadcrumb = page.get_by_role("navigation", name="Breadcrumb", exact=True)
    categories = page.get_by_role("navigation", name="Categories", exact=True)
    expect(breadcrumb.get_by_role("link", name="Asai Blog", exact=True)).to_be_visible()
    expect(breadcrumb.locator(".current-category")).to_have_text("All Notes")
    expect(page.locator(".tabbar, .active-tab, .tab-dot")).to_have_count(0)
    expect(page.get_by_role("link", name=re.compile("about", re.I))).to_have_count(0)
    expect(
        page.locator(".sidebar select, .sidebar .tag, .sidebar .topic")
    ).to_have_count(0)
    expect(categories.get_by_role("button")).to_have_count(3)
    categories.get_by_role("button", name="web").click()
    expect(breadcrumb.locator(".current-category")).to_have_text("web")
    expect(page.locator(".post-row")).to_have_count(2)
    add_tag(page, "elm")
    expect(page.locator(".post-row")).to_have_count(1)
    page.get_by_role("link", name="From plain text to a small, personal web").click()
    expect(breadcrumb.locator(".current-category")).to_have_text("web")
    expect(page.locator(".tabbar")).to_have_count(0)
    expect(page.locator(".tag-picker")).to_have_count(0)
    categories.get_by_role("link", name="notes").click()
    expect(page).to_have_url(re.compile("\\?category=notes$"))
    expect(breadcrumb.locator(".current-category")).to_have_text("notes")
    expect(page.locator(".post-row")).to_have_count(1)
    page.reload()
    expect(page.locator(".post-row")).to_have_count(1)
    breadcrumb.get_by_role("link", name="Asai Blog", exact=True).click()
    expect(page).to_have_url("/")
    expect(breadcrumb.locator(".current-category")).to_have_text("All Notes")
    expect(page.locator(".post-row")).to_have_count(4)


def test_direct_post_urls_display_their_folder_category_and_index_filters_accept_deep_links(
    page: Page,
) -> None:
    page.goto("/posts/types-as-design-tools/")
    expect(page.locator(".breadcrumbs .current-category")).to_have_text("programming")
    expect(page.locator(".category-item.active")).to_contain_text("programming")
    category_link = page.get_by_role(
        "navigation", name="Breadcrumb", exact=True
    ).get_by_role("link", name="programming", exact=True)
    expect(category_link).to_have_attribute("href", "/?category=programming")
    category_link.click()
    expect(page).to_have_url(re.compile("\\?category=programming$"))
    expect(page.locator(".post-row")).to_have_count(1)
    expect(page.locator(".post-row")).to_contain_text(
        "Types are a way to ask better questions"
    )
    page.goto("/?category=web&tag=notes")
    expect(page.locator(".post-row")).to_have_count(1)
    expect(page.locator(".post-row")).to_contain_text("A quieter interface")
    expect(
        page.get_by_role("button", name="Remove tag notes", exact=True)
    ).to_be_visible()
    page.get_by_role("navigation", name="Categories", exact=True).get_by_role(
        "button", name="programming"
    ).click()
    expect(page.locator(".post-row")).to_have_count(0)
    page.get_by_role("button", name="Clear filters →", exact=True).click()
    expect(page.locator(".post-row")).to_have_count(1)
    expect(page.locator(".breadcrumbs .current-category")).to_have_text("programming")
    assert query_param(page.url, "category") == "programming"
    assert query_params(page.url).get("tag", []) == []


def test_article_outline_is_transparent_stays_on_the_right_and_adapts_to_narrow_screens(
    page: Page,
) -> None:
    page.set_viewport_size({"width": 1920, "height": 900})
    page.goto("/")
    page.locator(".post-row h3 a").first.click()
    article_url = page.url
    outline = page.locator(".main-content > .page-outline")
    expect(outline).to_be_visible()
    expect(
        page.locator(".sidebar").get_by_role("navigation", name="Table of contents")
    ).to_have_count(0)
    expect(outline).to_have_css("background-color", "rgba(0, 0, 0, 0)")
    panel = bounds(outline)
    article = bounds(page.locator(".prose"))
    assert panel["x"] > article["x"] + article["width"]
    assert panel["x"] + panel["width"] > 1380
    page.screenshot(path="test-results/outline-desktop.png", full_page=True)
    link = outline.get_by_role("link").last
    target = link.get_attribute("href")
    assert target is not None and target.startswith("#")
    link.click()
    expect(page).to_have_url(re.compile(re.escape(target) + "$"))
    expect(page.locator(target)).to_be_in_viewport()
    expect(outline).to_be_in_viewport()
    assert bounds(outline)["y"] >= 0
    assert bounds(outline)["y"] <= 33
    for width in [1440, 1366, 1024, 768, 390]:
        page.set_viewport_size({"width": width, "height": 900})
        page.goto(article_url)
        expect(page.locator(".workspace")).to_be_visible()
        expect(outline).to_have_count(0)
        page.keyboard.press("o")
        expect(outline).to_be_visible()
        expect(outline).to_have_css("position", "static")
        narrow_panel = bounds(outline)
        narrow_article = bounds(page.locator(".prose"))
        assert narrow_panel["y"] + narrow_panel["height"] < narrow_article["y"]
        assert (
            page.evaluate("() => document.documentElement.scrollWidth <= innerWidth")
            is True
        )
    page.screenshot(path="test-results/outline-mobile.png", full_page=True)
    page.goto("/")
    expect(page.locator(".workspace")).to_be_visible()
    expect(page.locator(".page-outline")).to_have_count(0)


def test_note_tags_add_multiple_filters_deduplicate_and_persist_through_reload(
    page: Page,
) -> None:
    page.goto("/")
    first_post = page.locator(".post-row").filter(
        has_text="From plain text to a small, personal web"
    )
    first_post.get_by_role("button", name="Filter by tag haskell", exact=True).click()
    expect(page.locator(".post-row")).to_have_count(2)
    first_post.get_by_role("button", name="Filter by tag elm", exact=True).click()
    expect(page.locator(".post-row")).to_have_count(1)
    expect(
        page.get_by_role("group", name="Selected tags", exact=True).get_by_role(
            "button"
        )
    ).to_have_count(2)
    first_post.get_by_role("button", name="Filter by tag elm", exact=True).click()
    expect(page.locator(".selected-tag")).to_have_count(2)
    assert query_params(page.url).get("tag", []) == ["elm", "haskell"]
    page.reload()
    expect(page.locator(".post-row")).to_have_count(1)
    expect(page.locator(".selected-tag")).to_have_count(2)
    expect(
        first_post.get_by_role("button", name="Filter by tag elm", exact=True)
    ).to_have_attribute("aria-pressed", "true")
    page.get_by_role("button", name="Remove tag elm", exact=True).click()
    expect(page.locator(".post-row")).to_have_count(2)
    add_tag(page, "notes")
    expect(page.locator(".post-row")).to_have_count(0)
    page.get_by_role("button", name="Clear filters →", exact=True).click()
    expect(page.locator(".post-row")).to_have_count(4)
    assert urlsplit(page.url).query == ""


def test_tag_checkboxes_combine_with_category_and_search_and_repeated_url_tags_normalize(
    page: Page,
) -> None:
    page.goto("/?category=web&tag=haskell&tag=elm&tag=elm&q=compiler")
    expect(page.locator(".selected-tag")).to_have_count(2)
    expect(page.locator(".post-row")).to_have_count(1)
    page.locator(".tag-picker > summary").click()
    expect(
        page.get_by_role("checkbox", name="Select tag elm", exact=True)
    ).to_be_checked()
    expect(
        page.get_by_role("checkbox", name="Select tag haskell", exact=True)
    ).to_be_checked()
    page.get_by_role("checkbox", name="Select tag elm", exact=True).uncheck()
    page.locator(".tag-picker > summary").click()
    expect(page.locator(".selected-tag")).to_have_count(1)
    assert query_params(page.url).get("tag", []) == ["haskell"]
    assert query_param(page.url, "category") == "web"
    assert query_param(page.url, "q") == "compiler"
    page.get_by_role("searchbox").fill("no such phrase")
    expect(page.locator(".post-row")).to_have_count(0)
    page.get_by_role("button", name="Clear filters →", exact=True).click()
    expect(page.locator(".post-row")).to_have_count(0)
    expect(page.get_by_role("searchbox")).to_have_value("no such phrase")
    expect(page.locator(".breadcrumbs .current-category")).to_have_text("web")
    expect(page.locator(".selected-tag")).to_have_count(0)
    page.get_by_role("button", name="Clear search", exact=True).click()
    expect(page.locator(".post-row")).to_have_count(2)
    page.set_viewport_size({"width": 390, "height": 844})
    add_tag(page, "haskell")
    add_tag(page, "elm")
    assert (
        page.evaluate("() => document.documentElement.scrollWidth <= innerWidth")
        is True
    )
    page.screenshot(path="test-results/multiple-tags-mobile.png", full_page=True)


def test_clear_filters_only_removes_tags_and_preserves_category_navigation_and_search_text(
    page: Page,
) -> None:
    page.goto("/?category=web")
    expect(page.locator(".post-row")).to_have_count(2)
    expect(page.get_by_role("button", name="Clear filters", exact=True)).to_have_count(
        0
    )
    expect(page.get_by_role("status")).to_have_text("2 notes in web")
    page.get_by_role("searchbox").fill("compiler")
    expect(page.locator(".post-row")).to_have_count(1)
    expect(page.get_by_role("button", name="Clear filters", exact=True)).to_have_count(
        0
    )
    add_tag(page, "haskell")
    add_tag(page, "elm")
    expect(page.locator(".selected-tag")).to_have_count(2)
    page.get_by_role("button", name="Clear filters", exact=True).click()
    expect(page.locator(".selected-tag")).to_have_count(0)
    expect(page.get_by_role("searchbox")).to_have_value("compiler")
    expect(page.locator(".breadcrumbs .current-category")).to_have_text("web")
    expect(page.locator(".post-row")).to_have_count(1)
    params = query_params(page.url)
    assert params.get("category", [None])[0] == "web"
    assert params.get("q", [None])[0] == "compiler"
    assert params.get("tag", []) == []
    expect(page.get_by_role("button", name="Clear filters", exact=True)).to_have_count(
        0
    )
    page.reload()
    expect(page.locator(".post-row")).to_have_count(1)
    expect(page.locator(".breadcrumbs .current-category")).to_have_text("web")


def add_tag(page: Page, tag: str) -> None:
    picker = page.locator(".tag-picker > summary")
    picker.click()
    page.get_by_role("checkbox", name=f"Select tag {tag}", exact=True).check()
    picker.click()


def test_header_clock_uses_browser_local_24_hour_time_and_updates_at_minute_boundaries(
    browser: Browser, base_url: str
) -> None:
    cases = [
        (
            "Asia/Shanghai",
            "2026-09-09T15:59:59Z",
            "2026/09/09 23:59",
            "2026/09/10 00:00",
        ),
        (
            "Asia/Kathmandu",
            "2026-09-09T14:14:59Z",
            "2026/09/09 19:59",
            "2026/09/09 20:00",
        ),
        (
            "America/New_York",
            "2026-03-08T06:59:59Z",
            "2026/03/08 01:59",
            "2026/03/08 03:00",
        ),
    ]
    for zone, start, before, after in cases:
        context = browser.new_context(base_url=base_url, timezone_id=zone)
        try:
            page = context.new_page()
            instant = datetime.fromisoformat(start)
            page.clock.install(time=instant - timedelta(seconds=1))
            page.clock.pause_at(instant)
            page.goto("/")
            clock = page.get_by_label("Current local time", exact=True)
            expect(clock).to_have_text(before)
            expect(
                page.get_by_text("a corner of the internet", exact=True)
            ).to_have_count(0)
            page.clock.run_for(1100)
            expect(clock).to_have_text(after)
            expected_iso = (
                (instant + timedelta(seconds=1))
                .isoformat(timespec="milliseconds")
                .replace("+00:00", "Z")
            )
            expect(clock).to_have_attribute("datetime", expected_iso)
            for width in [390, 320]:
                page.set_viewport_size({"width": width, "height": 844})
                expect(clock).to_be_visible()
                assert page.evaluate(
                    "() => document.documentElement.scrollWidth <= innerWidth"
                )
        finally:
            context.close()


class Timings(TypedDict):
    loading: float
    rendering: float
    loadEvent: float
    elmStart: float
    paintOpportunity: float


def expect_page_timings(page: Page) -> Timings:
    footer = page.get_by_label("Page performance", exact=True)
    expect(footer).to_have_text(
        re.compile(r"^loading (0|[1-9]\d*)ms / rendered (0|[1-9]\d*)ms$")
    )
    measurements = cast(
        Timings,
        page.evaluate(r"""() => {
      const navigation = performance.getEntriesByType('navigation')[0];
      const start = performance.getEntriesByName('asai:elm-init')[0];
      const paint = performance.getEntriesByName('asai:first-paint-opportunity')[0];
      return {
        loading: navigation.loadEventStart - navigation.startTime,
        rendering: paint.startTime - start.startTime,
        loadEvent: navigation.loadEventStart,
        elmStart: start.startTime,
        paintOpportunity: paint.startTime,
      };
    }"""),
    )
    expect(footer).to_have_text(
        f"loading {floor(measurements['loading'] + 0.5)}ms / rendered {floor(measurements['rendering'] + 0.5)}ms"
    )
    return measurements


def test_footer_measures_navigation_load_independently_of_a_delayed_json_fetch(
    page: Page,
) -> None:
    with hold_requests(page, "**/api/posts.json") as index:
        page.goto("/")
        expect(page.locator(".workspace")).to_have_count(0)
        index.release()
        measurements = expect_page_timings(page)
        assert measurements["elmStart"] > measurements["loadEvent"]
        assert measurements["rendering"] > 0
        original = content_text(page.get_by_label("Page performance", exact=True))
        page.get_by_role("searchbox").fill("elm")
        expect(page.get_by_label("Page performance", exact=True)).to_have_text(original)
        expect(page.get_by_text("a work in progress", exact=False)).to_have_count(0)
        expect(
            page.locator(".sidebar").get_by_role("link", name="CC-BY-SA 4.0")
        ).to_have_attribute("href", "https://creativecommons.org/licenses/by-sa/4.0/")
        page.set_viewport_size({"width": 320, "height": 844})
        page.get_by_label("Page performance", exact=True).scroll_into_view_if_needed()
        expect(page.get_by_label("Page performance", exact=True)).to_be_in_viewport()
        assert page.evaluate("() => document.documentElement.scrollWidth <= innerWidth")


def test_startup_waits_for_assets_while_footer_retains_navigation_and_elm_rendering_boundaries(
    page: Page,
) -> None:
    with hold_requests(page, "**/attachments/pipeline.svg") as image:
        page.goto("/posts/plain-text-to-a-small-web/", wait_until="domcontentloaded")
        expect(page.locator("#loading-screen")).to_be_visible()
        expect(page.locator("#loading-status")).to_have_text("loading assets...")
        expect(page.locator(".workspace")).to_have_count(0)
        image.release()
        page.wait_for_load_state("load")
        measurements = expect_page_timings(page)
        assert measurements["elmStart"] >= measurements["loadEvent"]
        assert measurements["paintOpportunity"] > measurements["elmStart"]
