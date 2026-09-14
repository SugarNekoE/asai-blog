import re

from playwright.sync_api import Page, expect

from tests.cdp import capture_loading
from tests.helpers import fulfill_json, hold_requests


def test_loading_screen_displays_font_progress_before_revealing_the_page(
    page: Page,
) -> None:
    with hold_requests(page, "**/assets/fonts/*") as fonts:
        page.goto("/", wait_until="domcontentloaded")
        expect(
            page.get_by_role("heading", name="Please Be Patient", exact=True)
        ).to_be_visible()
        expect(page.locator("#loading-status")).to_have_text("loading fonts...")
        expect(page.locator("#app")).to_have_js_property("inert", True)
        capture_loading(page, "test-results/loading-desktop.png")
        page.set_viewport_size({"width": 390, "height": 844})
        expect(page.locator("#loading-screen")).to_be_in_viewport()
        assert page.evaluate("() => document.documentElement.scrollWidth <= innerWidth")
        capture_loading(page, "test-results/loading-mobile.png")
        fonts.release()
        expect(page.locator(".workspace")).to_be_visible()
        expect(page.locator("#loading-screen")).to_have_count(0)
        expect(page.locator("html")).not_to_have_class(re.compile("is-loading"))


def test_loader_is_visible_while_the_elm_bundle_downloads(page: Page) -> None:
    with hold_requests(page, "**/assets/elm.js*") as script:
        page.goto("/", wait_until="commit")
        expect(page.locator("#loading-screen")).to_be_visible()
        expect(page.locator("#loading-status")).to_have_text("loading assets...")
        script.release()
        expect(page.locator(".workspace")).to_be_visible()
        expect(page.locator("#loading-screen")).to_have_count(0)


def test_loader_reports_pending_notes_and_recovers_from_font_failures(
    page: Page,
) -> None:
    with hold_requests(page, "**/api/posts.json") as index:
        page.route("**/assets/fonts/*", lambda route: route.abort())
        page.goto("/")
        expect(page.locator("#loading-status")).to_have_text("loading notes...")
        index.release()
        expect(page.locator(".workspace")).to_be_visible()
        expect(page.locator("#loading-screen")).to_have_count(0)


def test_failed_startup_reveals_readable_static_html(page: Page) -> None:
    page.route(
        "**/api/posts.json", lambda route: route.fulfill(status=503, body="unavailable")
    )
    page.goto("/")
    expect(page.locator("#static-content")).to_be_visible()
    expect(page.locator("#app")).to_have_js_property("inert", False)
    expect(page.locator("#loading-screen")).to_have_count(0)
    page.unroute("**/api/posts.json")
    page.route("**/assets/elm.js*", lambda route: route.abort())
    page.reload()
    expect(page.locator("#static-content")).to_be_visible()
    expect(page.locator("#app")).to_have_js_property("inert", False)
    expect(page.locator("#loading-screen")).to_have_count(0)


def test_stalled_startup_times_out_to_the_static_page_without_a_late_takeover(
    page: Page,
) -> None:
    page.clock.install()
    with hold_requests(page, "**/assets/elm.js*") as script:
        page.goto("/", wait_until="commit")
        expect(page.locator("#loading-screen")).to_be_visible()
        page.clock.fast_forward(16000)
        expect(page.locator("#static-content")).to_be_visible()
        expect(page.locator("#app")).to_have_js_property("inert", False)
        expect(page.locator("#loading-screen")).to_have_count(0)
        script.release()
        page.wait_for_load_state("load")
        expect(page.locator(".workspace")).to_have_count(0)


def test_invalid_index_contracts_reveal_the_static_article_instead_of_mounting_elm(
    page: Page,
) -> None:
    page.goto("/")
    expect(page.locator(".workspace")).to_be_visible()
    page.locator(".post-row h3 a").first.click()
    title = page.locator(".prose h1").inner_text()
    url = page.url
    indexes: list[dict[str, object]] = [
        {"version": 99, "posts": []},
        {"version": 2, "posts": "invalid"},
    ]
    for index in indexes:
        page.route("**/api/posts.json", fulfill_json(index))
        page.goto(url)
        expect(page.locator("#static-content h1")).to_have_text(title)
        expect(page.locator("#static-content")).to_be_visible()
        expect(page.locator("#loading-screen")).to_have_count(0)
        expect(page.locator("#app")).to_have_js_property("inert", False)
        expect(page.locator(".workspace")).to_have_count(0)
        page.unroute("**/api/posts.json")


def test_a_late_elm_http_response_cannot_replace_the_fallback_after_startup_expires(
    page: Page,
) -> None:
    page.clock.install()
    with hold_requests(page, "**/api/posts.json") as index:
        page.goto("/")
        expect(page.locator("#loading-status")).to_have_text("loading notes...")
        page.clock.fast_forward(16000)
        expect(page.locator("#static-content")).to_be_visible()
        expect(page.locator("#app")).to_have_js_property("inert", False)
        with page.expect_response("**/api/posts.json"):
            index.release()
        page.clock.run_for(100)
        expect(page.locator(".workspace")).to_have_count(0)
        assert (
            page.evaluate("() => performance.getEntriesByName('asai:elm-init')") == []
        )
