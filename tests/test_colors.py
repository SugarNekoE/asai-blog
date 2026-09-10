from pathlib import Path

from playwright.sync_api import Page, expect

from scripts.site_data import read_index


def test_tag_mappings_are_shared_by_badges_chips_picker_labels_and_launcher_results_in_both_themes(
    page: Page,
) -> None:
    page.goto("/")
    badge = page.locator('.post-row .tag[data-tag="elm"]')
    badge.click()
    page.mouse.move(0, 0)
    for theme, color in [
        ["dark", "rgb(120, 220, 232)"],
        ["light", "rgb(37, 112, 123)"],
    ]:
        expect(page.locator("html")).to_have_attribute("data-theme", theme)
        expect(badge).to_have_css("color", color)
        expect(page.locator('.selected-tag[data-tag="elm"]')).to_have_css(
            "color", color
        )
        expect(page.locator('.tag-option[data-tag="elm"]')).to_have_css("color", color)
        page.locator(".search-launch").click()
        expect(
            page.get_by_role("dialog", name="Search notes", exact=True)
        ).to_be_visible()
        expect(page.locator('.launcher-tag[data-tag="elm"]')).to_have_css(
            "color", color
        )
        page.keyboard.press("Escape")
        page.screenshot(path=f"test-results/colors-{theme}.png", animations="disabled")
        if theme == "dark":
            page.get_by_role("button", name="Toggle color theme", exact=True).click()


def test_editing_only_the_color_config_remaps_tags_and_accents_including_special_character_tags(
    page: Page,
) -> None:
    original = Path("static/assets/colors.css").read_text()
    custom = (
        original.replace(
            "--tag-color: var(--monokai-pro-blue);",
            "--tag-color: var(--monokai-pro-red);",
        ).replace(
            "--accent: var(--monokai-pro-green);", "--accent: var(--monokai-pro-blue);"
        )
        + '\n[data-tag="c++"] { --tag-color: var(--monokai-pro-orange); }\n'
    )
    page.route(
        "**/assets/colors.css*",
        lambda route: route.fulfill(body=custom, content_type="text/css"),
    )
    data = read_index(Path("_site/api/posts.json"))
    data["posts"][0]["tags"].extend(["c++", "unmapped"])
    page.route("**/api/posts.json", lambda route: route.fulfill(json=data))
    page.goto("/")
    elm = page.locator('.post-row .tag[data-tag="elm"]')
    expect(elm).to_have_css("color", "rgb(255, 97, 136)")
    expect(page.locator(".intro em")).to_have_css("color", "rgb(120, 220, 232)")
    expect(page.locator('.tag[data-tag="c++"]')).to_have_css(
        "color", "rgb(252, 152, 103)"
    )
    expect(page.locator('.tag[data-tag="unmapped"]')).to_have_css(
        "color", "rgb(171, 157, 242)"
    )
    dark_tint = elm.evaluate("(node) => getComputedStyle(node).backgroundColor")
    dark_border = elm.evaluate("(node) => getComputedStyle(node).borderTopColor")
    assert dark_tint != "rgba(0, 0, 0, 0)"
    elm.click()
    expect(page.locator('.selected-tag[data-tag="elm"]')).to_have_css(
        "color", "rgb(255, 97, 136)"
    )
    page.get_by_role("button", name="Toggle color theme", exact=True).click()
    expect(elm).to_have_css("color", "rgb(181, 53, 91)")
    expect(page.locator(".intro em")).to_have_css("color", "rgb(37, 112, 123)")
    assert elm.evaluate("(node) => getComputedStyle(node).backgroundColor") != dark_tint
    assert (
        elm.evaluate("(node) => getComputedStyle(node).borderTopColor") != dark_border
    )
