from playwright.sync_api import Page, expect

from tests.helpers import bounds


def open_article(page: Page) -> None:
    page.goto("/")
    expect(page.locator(".workspace")).to_be_visible()
    page.locator(".post-row h3 a").first.click()
    expect(page.locator(".workspace")).to_be_visible()
    expect(page.locator(".prose")).to_be_visible()


def test_wide_screen_outline_uses_right_gutter_without_shifting_article(
    page: Page,
) -> None:
    for width in [1600, 1920, 2048, 2560]:
        page.set_viewport_size({"width": width, "height": 1000})
        page.goto("/")
        expect(page.locator(".workspace")).to_be_visible()
        index = bounds(page.locator(".page-content"))
        page.locator(".post-row h3 a").first.click()
        outline = page.locator(".page-outline")
        expect(outline).to_be_visible()
        article = bounds(page.locator(".prose"))
        panel = bounds(outline)
        assert abs(article["x"] - index["x"]) < 1
        assert abs(article["width"] - index["width"]) < 1
        assert abs(article["width"] - 730) < 1
        assert abs(panel["width"] - 200) < 1
        assert abs(width - panel["x"] - panel["width"] - 40) < 1
        assert panel["x"] - article["x"] - article["width"] >= 64
        assert (
            page.evaluate("() => document.documentElement.scrollWidth <= innerWidth")
            is True
        )
        page.screenshot(path=f"test-results/outline-wide-{width}.png")
        page.keyboard.press("o")
        expect(outline).to_have_count(0)
        hidden = bounds(page.locator(".prose"))
        assert abs(hidden["x"] - article["x"]) < 1
        assert abs(hidden["width"] - article["width"]) < 1


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
                extra.removeAttribute('aria-current');
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


def test_outline_highlight_tracks_scrolling_links_and_reload_without_changing_focus(
    page: Page,
) -> None:
    page.set_viewport_size({"width": 1920, "height": 900})
    page.emulate_media(reduced_motion="reduce")
    open_article(page)
    outline = page.locator(".page-outline")
    links = outline.get_by_role("link")
    targets = [link.get_attribute("href") for link in links.all()]
    assert len(targets) >= 3
    first, middle, last = targets[0], targets[len(targets) // 2], targets[-1]
    assert first is not None and middle is not None and last is not None
    current = outline.locator('[aria-current="location"]')
    expect(current).to_have_count(1)
    expect(current).to_have_attribute("href", first)
    focus = page.get_by_role("button", name="Toggle color theme", exact=True)
    focus.focus()
    page.evaluate(
        "id => document.getElementById(id).scrollIntoView({block: 'start', behavior: 'instant'})",
        middle[1:],
    )
    expect(current).to_have_attribute("href", middle)
    expect(focus).to_be_focused()
    inactive_color = links.first.evaluate("node => getComputedStyle(node).color")
    expect(current).not_to_have_css("color", inactive_color)
    expect(current).to_have_css("background-color", "rgba(0, 0, 0, 0)")
    expect(current).to_have_css("box-shadow", "none")
    links.last.click()
    expect(current).to_have_attribute("href", last)
    page.reload()
    expect(current).to_have_attribute("href", last)
    page.evaluate("() => window.scrollTo({top: 0, behavior: 'instant'})")
    expect(current).to_have_attribute("href", first)
    expect(current).to_have_count(1)
    page.mouse.move(0, 0)
    page.screenshot(path="test-results/outline-current-desktop.png")


def test_current_outline_link_stays_visible_in_its_scroll_area_without_scrolling_article(
    page: Page,
) -> None:
    page.set_viewport_size({"width": 1920, "height": 480})
    page.emulate_media(reduced_motion="reduce")
    open_article(page)
    outline = page.locator(".page-outline")
    links = outline.get_by_role("navigation", name="Table of contents")
    target = links.locator("a").last.get_attribute("href")
    assert target is not None
    position = page.evaluate(
        """() => {
          window.scrollTo({top: document.documentElement.scrollHeight, behavior: 'instant'});
          return window.scrollY;
        }"""
    )
    current = links.locator('[aria-current="location"]')
    expect(current).to_have_attribute("href", target)
    expect(current).to_be_in_viewport()
    assert links.evaluate("nav => nav.scrollTop > 0") is True
    assert page.evaluate("() => window.scrollY") == position
    page.screenshot(path="test-results/outline-current-scroll.png")


def test_outline_highlight_updates_while_hidden_and_in_the_mobile_outline(
    page: Page,
) -> None:
    for width in [1920, 390]:
        page.set_viewport_size({"width": width, "height": 900})
        page.emulate_media(reduced_motion="reduce")
        open_article(page)
        outline = page.locator(".page-outline")
        if width < 1600:
            page.keyboard.press("o")
        expect(outline).to_be_visible()
        targets = outline.get_by_role("link")
        target = targets.nth(targets.count() // 2).get_attribute("href")
        assert target is not None
        page.keyboard.press("o")
        expect(outline).to_have_count(0)
        page.evaluate(
            "id => document.getElementById(id).scrollIntoView({block: 'start', behavior: 'instant'})",
            target[1:],
        )
        page.keyboard.press("o")
        expect(outline).to_be_visible()
        page.evaluate(
            "id => document.getElementById(id).scrollIntoView({block: 'start', behavior: 'instant'})",
            target[1:],
        )
        expect(outline.locator('[aria-current="location"]')).to_have_attribute(
            "href", target
        )
        expect(outline.locator('[aria-current="location"]')).to_have_count(1)
        if width < 1600:
            page.evaluate("() => window.scrollTo({top: 0, behavior: 'instant'})")
            expect(outline.locator('[aria-current="location"]')).to_have_attribute(
                "href", targets.first.get_attribute("href") or ""
            )
            page.screenshot(path="test-results/outline-current-mobile.png")
