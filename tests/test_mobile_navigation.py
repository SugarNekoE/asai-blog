import pytest
from playwright.sync_api import Browser, Locator, Page, Position, expect

from tests.helpers import bounds


@pytest.mark.parametrize("touch", [False, True])
def test_mobile_menu_closes_outside_without_blocking_the_clicked_control(
    browser: Browser, base_url: str, touch: bool
) -> None:
    context = browser.new_context(
        base_url=base_url,
        viewport={"width": 390, "height": 844},
        has_touch=touch,
        is_mobile=touch,
    )
    try:
        page = context.new_page()
        page.goto("/")
        expect(page.locator(".workspace")).to_be_visible()
        toggle = page.get_by_role("button", name="Toggle navigation", exact=True)
        sidebar = page.locator(".sidebar")

        def activate(control: Locator) -> None:
            if touch:
                control.tap()
            else:
                control.click()

        activate(toggle)
        expect(sidebar).to_be_visible()
        expect(toggle).to_have_attribute("aria-expanded", "true")
        activate(sidebar.locator(".sidebar-label").first)
        expect(sidebar).to_be_visible()
        activate(toggle)
        expect(sidebar).to_be_hidden()
        activate(toggle)
        activate(page.get_by_role("button", name="Toggle color theme", exact=True))
        expect(sidebar).to_be_hidden()
        expect(page.locator("html")).to_have_attribute("data-theme", "light")
        expect(page.locator("html")).to_have_attribute("data-theme-preference", "light")
        activate(toggle)
        content = page.locator(".page-content")
        position: Position = {"x": bounds(content)["width"] - 8, "y": 12}
        if touch:
            content.tap(position=position)
        else:
            content.click(position=position)
        expect(sidebar).to_be_hidden()
        expect(toggle).to_have_attribute("aria-expanded", "false")
    finally:
        context.close()


def test_mobile_menu_stays_attached_to_header_during_page_and_menu_scrolling(
    page: Page,
) -> None:
    for width in [320, 390, 760]:
        page.set_viewport_size({"width": width, "height": 640})
        page.goto("/")
        expect(page.locator(".workspace")).to_be_visible()
        page.locator(".post-row h3 a").first.click()
        expect(page.locator(".workspace")).to_be_visible()
        toggle = page.get_by_role("button", name="Toggle navigation", exact=True)
        sidebar = page.locator(".sidebar")
        topbar = page.locator(".topbar")
        toggle.click()
        expect(sidebar).to_be_visible()
        page.evaluate("() => window.scrollTo({ top: 600, behavior: 'instant' })")
        page.wait_for_function("() => window.scrollY > 300")
        header = bounds(topbar)
        assert abs(header["y"]) < 1
        assert abs(bounds(sidebar)["y"] - header["y"] - header["height"]) < 1
        page.screenshot(path=f"test-results/mobile-menu-scrolled-{width}.png")

        sidebar.locator(".category-list").evaluate(
            """(nav) => {
              const category = nav.querySelector('a, button');
              for (let i = 0; i < 35; i++) {
                const extra = category.cloneNode(true);
                extra.textContent = `Additional category ${i + 1}`;
                nav.append(extra);
              }
            }"""
        )
        assert sidebar.evaluate("node => node.scrollHeight > node.clientHeight") is True
        page_y = page.evaluate("() => window.scrollY")
        sidebar.hover()
        page.mouse.wheel(0, 600)
        page.wait_for_function("() => document.querySelector('.sidebar').scrollTop > 0")
        assert page.evaluate("() => window.scrollY") == page_y
        sidebar.evaluate("node => { node.scrollTop = node.scrollHeight; }")
        page.mouse.wheel(0, 400)
        page.evaluate(
            "() => new Promise(resolve => requestAnimationFrame(() => requestAnimationFrame(resolve)))"
        )
        assert page.evaluate("() => window.scrollY") == page_y
        assert abs(bounds(sidebar)["y"] - bounds(topbar)["height"]) < 1
        toggle.click()
        expect(sidebar).to_be_hidden()


def test_mobile_outline_links_land_below_the_sticky_header(page: Page) -> None:
    page.set_viewport_size({"width": 390, "height": 844})
    page.goto("/")
    expect(page.locator(".workspace")).to_be_visible()
    page.locator(".post-row h3 a").first.click()
    expect(page.locator(".workspace")).to_be_visible()
    page.keyboard.press("o")
    link = page.locator(".page-outline nav a").first
    target = link.get_attribute("href")
    assert target is not None and target.startswith("#")
    link.click()
    heading = page.locator(target)
    expect(heading).to_be_in_viewport()
    topbar = bounds(page.locator(".topbar"))
    assert bounds(heading)["y"] >= topbar["y"] + topbar["height"]
