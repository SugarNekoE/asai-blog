from playwright.sync_api import Page, expect

from tests.helpers import bounds


def open_article(page: Page) -> None:
    page.goto("/")
    expect(page.locator(".workspace")).to_be_visible()
    page.locator(".post-row h3 a").first.click()
    expect(page.locator(".workspace")).to_be_visible()
    expect(page.locator(".prose")).to_be_visible()


def test_outline_default_follows_screen_width_until_manually_toggled(
    page: Page,
) -> None:
    page.set_viewport_size({"width": 1366, "height": 768})
    open_article(page)
    outline = page.locator(".page-outline")
    expect(outline).to_have_count(0)
    expect(page.locator(".article-header h1")).to_be_in_viewport()

    page.set_viewport_size({"width": 1920, "height": 900})
    expect(outline).to_be_visible()
    page.set_viewport_size({"width": 1366, "height": 768})
    expect(outline).to_have_count(0)
    page.keyboard.press("o")
    expect(outline).to_be_visible()
    page.set_viewport_size({"width": 390, "height": 844})
    expect(outline).to_be_visible()
    page.keyboard.press("o")
    expect(outline).to_have_count(0)
    page.set_viewport_size({"width": 1920, "height": 900})
    expect(outline).to_have_count(0)
    page.reload()
    expect(outline).to_be_visible()


def test_small_screen_outline_opens_above_article_and_scrolls_its_links(
    page: Page,
) -> None:
    for width in [1366, 1024, 390]:
        page.set_viewport_size({"width": width, "height": 768})
        open_article(page)
        outline = page.locator(".page-outline")
        expect(outline).to_have_count(0)
        page.screenshot(path=f"test-results/outline-default-{width}.png")
        page.keyboard.press("o")
        expect(outline).to_be_visible()
        links = outline.get_by_role("navigation", name="Table of contents")
        target = links.locator("a").first.get_attribute("href")
        assert target is not None and target.startswith("#")
        links.evaluate(
            """(nav) => {
              const link = nav.querySelector('a');
              for (let i = 0; i < 30; i++) {
                const extra = link.cloneNode(true);
                extra.textContent = `Additional section ${i + 1}`;
                nav.append(extra);
              }
            }"""
        )
        assert bounds(outline)["height"] <= 201
        assert links.evaluate("nav => nav.scrollHeight > nav.clientHeight") is True
        assert (
            bounds(outline)["y"] + bounds(outline)["height"]
            < bounds(page.locator(".prose"))["y"]
        )
        expect(page.locator(".article-header h1")).to_be_in_viewport()
        title = outline.locator("h2")
        title_y = bounds(title)["y"]
        page_y = page.evaluate("() => window.scrollY")
        links.hover()
        page.mouse.wheel(0, 400)
        page.wait_for_function(
            "() => document.querySelector('.page-outline nav').scrollTop > 0"
        )
        assert page.evaluate("() => window.scrollY") == page_y
        assert abs(bounds(title)["y"] - title_y) < 1
        page.screenshot(path=f"test-results/outline-open-{width}.png")
        last = links.locator("a").last
        last.focus()
        expect(last).to_be_in_viewport()
        last.press("Enter")
        expect(page.locator(target)).to_be_in_viewport()
