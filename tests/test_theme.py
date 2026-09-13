import json
from typing import Literal

import pytest
from playwright.sync_api import Page, expect

from tests.helpers import hold_requests

type Scheme = Literal["dark", "light"]


@pytest.mark.parametrize("scheme", ["dark", "light"])
def test_auto_theme_applies_before_elm_and_follows_system_changes(
    page: Page, scheme: Scheme
) -> None:
    page.emulate_media(color_scheme=scheme)
    with hold_requests(page, "**/assets/elm.js*") as bundle:
        page.goto("/", wait_until="commit")
        expect(page.locator("html")).to_have_attribute("data-theme", scheme)
        expect(page.locator("html")).to_have_attribute("data-theme-preference", "auto")
        expect(page.locator("html")).to_have_css("color-scheme", scheme)
        expect(page.locator(".workspace")).to_have_count(0)
        bundle.release()
        expect(page.locator(".workspace")).to_be_visible()
    page.emulate_media(color_scheme="light" if scheme == "dark" else "dark")
    expect(page.locator("html")).to_have_attribute(
        "data-theme", "light" if scheme == "dark" else "dark"
    )
    toggle = page.get_by_role("button", name="Toggle color theme", exact=True)
    expect(toggle).to_have_attribute("data-theme-preference", "auto")
    expect(toggle).to_have_text("◐")


@pytest.mark.parametrize("width,scheme", [(1280, "dark"), (390, "light")])
def test_theme_control_cycles_three_states_and_preserves_them_on_reload(
    page: Page, width: int, scheme: Scheme
) -> None:
    page.set_viewport_size({"width": width, "height": 844})
    page.emulate_media(color_scheme=scheme)
    page.goto("/")
    expect(page.locator(".workspace")).to_be_visible()
    toggle = page.get_by_role("button", name="Toggle color theme", exact=True)
    expect(toggle).to_have_attribute("data-theme-preference", "auto")
    for preference, icon in [("light", "☼"), ("dark", "☾"), ("auto", "◐")]:
        toggle.click()
        resolved = scheme if preference == "auto" else preference
        expect(page.locator("html")).to_have_attribute("data-theme", resolved)
        expect(toggle).to_have_attribute("data-theme-preference", preference)
        expect(toggle).to_have_text(icon)
        assert page.evaluate("() => localStorage.getItem('asai-theme')") == preference
        page.reload()
        expect(page.locator(".workspace")).to_be_visible()
        expect(toggle).to_have_attribute("data-theme-preference", preference)
        expect(toggle).to_have_text(icon)
        expect(page.locator("html")).to_have_attribute("data-theme", resolved)
        expect(page.locator("html")).to_have_css("color-scheme", resolved)
        page.screenshot(path=f"test-results/theme-{preference}-{width}.png")


@pytest.mark.parametrize("preference", ["light", "dark"])
def test_explicit_theme_ignores_system_changes(page: Page, preference: Scheme) -> None:
    page.goto("/")
    expect(page.locator(".workspace")).to_be_visible()
    toggle = page.get_by_role("button", name="Toggle color theme", exact=True)
    toggle.click()
    if preference == "dark":
        toggle.click()
    schemes: list[Scheme] = ["light", "dark"]
    for scheme in schemes:
        page.emulate_media(color_scheme=scheme)
        expect(page.locator("html")).to_have_attribute("data-theme", preference)
        expect(toggle).to_have_attribute("data-theme-preference", preference)


@pytest.mark.parametrize("saved", ["light", "dark", "invalid"])
def test_existing_theme_choices_are_preserved_and_invalid_values_use_auto(
    page: Page, saved: str
) -> None:
    page.add_init_script(f"localStorage.setItem('asai-theme', {json.dumps(saved)});")
    page.goto("/")
    expect(page.locator(".workspace")).to_be_visible()
    expect(page.locator("html")).to_have_attribute(
        "data-theme-preference", "auto" if saved == "invalid" else saved
    )
    expect(page.locator("html")).to_have_attribute(
        "data-theme", "dark" if saved == "invalid" else saved
    )


def test_theme_works_when_storage_is_unavailable(page: Page) -> None:
    page.add_init_script(
        """(() => {
          Object.defineProperty(window, 'localStorage', {
            get() { throw new Error('Storage is disabled'); }
          });
        })();"""
    )
    page.emulate_media(color_scheme="light")
    page.goto("/")
    expect(page.locator(".workspace")).to_be_visible()
    expect(page.locator("html")).to_have_attribute("data-theme", "light")
    page.emulate_media(color_scheme="dark")
    expect(page.locator("html")).to_have_attribute("data-theme", "dark")
    page.get_by_role("button", name="Toggle color theme", exact=True).click()
    expect(page.locator("html")).to_have_attribute("data-theme", "light")
    expect(page.locator("html")).to_have_attribute("data-theme-preference", "light")


def test_static_fallback_follows_system_theme_when_the_index_fails(page: Page) -> None:
    page.route(
        "**/api/posts.json", lambda route: route.fulfill(status=503, body="offline")
    )
    page.emulate_media(color_scheme="light")
    page.goto("/")
    expect(page.locator("#static-content")).to_be_visible()
    expect(page.locator(".workspace")).to_have_count(0)
    expect(page.locator("html")).to_have_attribute("data-theme", "light")
    page.emulate_media(color_scheme="dark")
    expect(page.locator("html")).to_have_attribute("data-theme", "dark")


def test_theme_keyboard_shortcut_cycles_the_same_preferences(page: Page) -> None:
    page.goto("/")
    expect(page.locator(".workspace")).to_be_visible()
    toggle = page.get_by_role("button", name="Toggle color theme", exact=True)
    for preference in ["light", "dark", "auto"]:
        page.keyboard.press("t")
        expect(toggle).to_have_attribute("data-theme-preference", preference)
