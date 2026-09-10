from datetime import date, timedelta
from urllib.parse import urlsplit

import pytest
from playwright.sync_api import Page, expect

from scripts.site_data import Post
from tests.helpers import (
    fulfill_json,
    query_param,
    query_params,
)


def test_elm_query_state_preserves_repeated_tags_encoded_values_extra_parameters_and_current_anchors(
    page: Page,
) -> None:
    page.goto(
        "/?category=web&tag=even&tag=shared&q=Entry+0&page=2&perPage=30&sort=oldest&campaign=%E4%B8%AD%E6%96%87+a%2Bb%3Dc#main"
    )
    expect(page.locator(".post-row")).to_have_count(10)
    search = page.get_by_role("searchbox")
    expect(search).to_have_value("Entry 0")
    expect(page.locator(".selected-tag")).to_have_count(2)
    page.evaluate(r"""() => {
      location.hash = 'notebook-heading';
    }""")
    search.fill("Entry 001")
    page.wait_for_url(lambda current_url: query_param(current_url, "q") == "Entry 001")
    url = page.url
    assert query_params(url).get("tag", []) == ["even", "shared"]
    assert query_param(url, "category") == "web"
    assert query_param(url, "perPage") == "30"
    assert query_param(url, "sort") == "oldest"
    assert query_param(url, "campaign") == "中文 a+b=c"
    assert ("page" in query_params(url)) is False
    assert "#" + urlsplit(url).fragment == "#notebook-heading"
    page.reload()
    expect(search).to_have_value("Entry 001")
    expect(page.locator(".post-row")).to_have_count(1)


def test_default_pages_contain_at_most_ten_notes_with_working_boundaries_and_reloads(
    page: Page,
) -> None:
    page.goto("/")
    rows = page.locator(".post-row")
    navigation = page.get_by_role("navigation", name="Notes pagination", exact=True)
    expect(rows).to_have_count(10)
    expect(rows.first).to_contain_text("Entry 137")
    expect(rows.last).to_contain_text("Entry 128")
    expect(page.get_by_label("Notes per page")).to_have_value("10")
    expect(page.locator(".pagination-summary")).to_have_text("1–10 of 137 notes")
    expect(
        navigation.get_by_role("button", name="Previous", exact=True)
    ).to_be_disabled()
    expect(page.locator(".notebook-end")).to_have_count(0)
    navigation.get_by_role("button", name="Next", exact=True).click()
    expect(rows.first).to_contain_text("Entry 127")
    expect(rows.first.locator(".post-kicker")).to_contain_text("NOTE 11")
    expect(page.locator(".pagination-summary")).to_have_text("11–20 of 137 notes")
    expect(page.locator("#notebook-heading")).to_be_focused()
    assert query_param(page.url, "page") == "2"
    page.reload()
    expect(rows.first).to_contain_text("Entry 127")
    navigation.get_by_role("button", name="Go to page 14", exact=True).click()
    expect(rows).to_have_count(7)
    expect(rows.last).to_contain_text("Entry 001")
    expect(navigation.get_by_role("button", name="Next", exact=True)).to_be_disabled()
    expect(page.locator(".notebook-end")).to_be_visible()
    navigation.get_by_role("button", name="Go to page 1", exact=True).click()
    expect(rows).to_have_count(10)
    assert ("page" in query_params(page.url)) is False


def test_page_size_choices_are_10_30_50_100_and_reset_pagination(page: Page) -> None:
    page.goto("/?page=4")
    size = page.get_by_label("Notes per page")
    expect(size.locator("option")).to_have_text(["10", "30", "50", "100"])
    for count in [30, 50, 100, 10]:
        size.select_option(str(count))
        expect(page.locator(".post-row")).to_have_count(count)
        expect(page.locator(".post-row").first).to_contain_text("Entry 137")
        expect(
            page.get_by_role("button", name="Go to page 1", exact=True)
        ).to_have_attribute("aria-current", "page")
        page.reload()
        expect(size).to_have_value(str(count))
        expect(page.locator(".post-row")).to_have_count(count)
    page.set_viewport_size({"width": 390, "height": 844})
    page.locator(".pagination").scroll_into_view_if_needed()
    assert (
        page.evaluate("() => document.documentElement.scrollWidth <= innerWidth")
        is True
    )
    page.locator(".pagination").screenshot(path="test-results/pagination-mobile.png")


def test_pagination_applies_after_category_and_tags_while_clear_filters_preserves_category_and_page_size(
    page: Page,
) -> None:
    page.goto("/?category=web&page=3&perPage=30")
    expect(page.locator(".post-row")).to_have_count(20)
    page.locator(".tag-picker > summary").click()
    page.get_by_role("checkbox", name="Select tag even", exact=True).check()
    page.locator(".tag-picker > summary").click()
    expect(page.locator(".post-row")).to_have_count(30)
    expect(page.locator(".pagination-summary")).to_have_text("1–30 of 40 notes")
    page.get_by_role("navigation", name="Notes pagination", exact=True).get_by_role(
        "button", name="Next", exact=True
    ).click()
    expect(page.locator(".post-row")).to_have_count(10)
    page.get_by_role("button", name="Clear filters", exact=True).click()
    expect(page.locator(".pagination-summary")).to_have_text("1–30 of 80 notes")
    expect(page.locator(".breadcrumbs .current-category")).to_have_text("web")
    expect(page.get_by_label("Notes per page")).to_have_value("30")
    page.get_by_role("searchbox").fill("Entry 001")
    expect(page.locator(".post-row")).to_have_count(1)
    expect(page.locator(".pagination-summary")).to_have_text("1–1 of 1 notes")
    page.get_by_role("searchbox").fill("")
    page.get_by_role("navigation", name="Notes pagination", exact=True).get_by_role(
        "button", name="Next", exact=True
    ).click()
    page.get_by_role("button", name="Newest first", exact=True).click()
    expect(page.locator(".post-row").first).to_contain_text("Entry 001")
    page.reload()
    expect(page.locator(".post-row").first).to_contain_text("Entry 001")
    expect(page.get_by_role("button", name="Oldest first", exact=True)).to_be_visible()


def test_invalid_pagination_is_bounded_and_empty_results_have_disabled_navigation(
    page: Page,
) -> None:
    for query in ["page=-1&perPage=20", "page=oops&perPage=0", "page=1.5&perPage=999"]:
        page.goto("/?" + query)
        expect(page.locator(".post-row")).to_have_count(10)
        expect(page.locator(".post-row").first).to_contain_text("Entry 137")
        expect(page.get_by_label("Notes per page")).to_have_value("10")
    page.goto("/?page=999&perPage=100")
    expect(page.locator(".post-row")).to_have_count(37)
    expect(
        page.get_by_role("button", name="Go to page 2", exact=True)
    ).to_have_attribute("aria-current", "page")
    page.get_by_role("searchbox").fill("no matching note")
    expect(page.locator(".post-row")).to_have_count(0)
    expect(page.locator(".pagination-summary")).to_have_text("0 notes")
    navigation = page.get_by_role("navigation", name="Notes pagination", exact=True)
    expect(
        navigation.get_by_role("button", name="Previous", exact=True)
    ).to_be_disabled()
    expect(navigation.get_by_role("button", name="Next", exact=True)).to_be_disabled()
    expect(page.locator(".notebook-end")).to_have_count(0)


@pytest.fixture(autouse=True)
def sample_posts(page: Page) -> None:
    posts: list[Post] = [
        {
            "title": f"Entry {index + 1:03}",
            "description": f"Description for entry {index + 1}",
            "date": (date(2025, 1, 1) + timedelta(days=index)).isoformat(),
            "url": f"/posts/entry-{index + 1}/",
            "category": "web" if index < 80 else "notes",
            "tags": ["even" if index % 2 == 0 else "odd", "shared"],
            "readingMinutes": 1,
            "searchText": f"Body of entry {index + 1}",
        }
        for index in range(137)
    ]
    page.route("**/api/posts.json", fulfill_json({"version": 2, "posts": posts}))
