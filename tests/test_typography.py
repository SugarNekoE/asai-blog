from urllib.parse import urlsplit

from playwright.sync_api import Page, Request, expect

from tests.cdp import platform_fonts
from tests.helpers import bounds


def test_bundled_text_fonts_cover_body_italic_code_and_cjk_without_installed_fonts(
    page: Page,
) -> None:
    font_requests: list[str] = []

    def record_font_request(request: Request) -> None:
        if request.resource_type == "font":
            font_requests.append(request.url)

    page.on("request", record_font_request)
    page.goto("/")
    expect(page.locator(".workspace")).to_be_visible()
    samples = [
        {"text": "Asai Blog Æ Ω Ж", "family": "Noto Sans", "stack": "--sans"},
        {
            "text": "Italic words",
            "family": "Noto Sans",
            "stack": "--sans",
            "style": "italic",
        },
        {"text": "const value = 123;", "family": "Noto Sans Mono", "stack": "--mono"},
        {
            "text": "简体漢字繁體かなカナ한글",
            "family": "Noto Sans CJK SC",
            "stack": "--sans",
        },
        {
            "text": "简体漢字繁體かなカナ한글",
            "family": "Noto Sans Mono CJK SC",
            "stack": "--mono",
        },
    ]
    page.evaluate(
        r"""async (samples) => {
      for (const [index, sample] of samples.entries()) {
        const node = document.createElement('p');
        node.id = `font-sample-${index}`;
        node.textContent = sample.text;
        node.style.fontFamily = `var(${sample.stack})`;
        node.style.fontStyle = sample.style || 'normal';
        document.body.append(node);
        await document.fonts.load(
          `${sample.style || 'normal'} 400 20px "${sample.family}"`,
          sample.text,
        );
      }
      await document.fonts.ready;
    }""",
        samples,
    )
    for index, sample in enumerate(samples):
        fonts = platform_fonts(page, f"#font-sample-{index}")
        assert len(fonts) > 0
        assert (
            all(
                font["isCustomFont"] and font["familyName"] == sample["family"]
                for font in fonts
            )
            is True
        )
    assert any(url.endswith("NotoSans.woff2") for url in font_requests) is True
    assert any("NotoSansCJKsc-" in url for url in font_requests) is True
    assert (
        all(
            (urlsplit(url).scheme, urlsplit(url).netloc)
            == (urlsplit(page.url).scheme, urlsplit(page.url).netloc)
            for url in font_requests
        )
        is True
    )


def test_bundled_noto_symbol_fonts_render_icons_in_aligned_containers(
    page: Page,
) -> None:
    page.set_viewport_size({"width": 1440, "height": 900})
    page.goto("/")
    expect(page.locator(".workspace")).to_be_visible()
    page.evaluate(r"""async () => {
      await document.fonts.load('400 20px "Noto Sans Symbols"', '↗');
      await document.fonts.load('400 20px "Noto Sans Symbols 2"', '◐☼☾');
      await document.fonts.ready;
    }""")
    theme_button = page.get_by_role("button", name="Toggle color theme", exact=True)
    for preference, theme in [("auto", "dark"), ("light", "light"), ("dark", "dark")]:
        expect(page.locator("html")).to_have_attribute("data-theme", theme)
        expect(theme_button).to_have_attribute("data-theme-preference", preference)
        fonts = platform_fonts(page, ".top-actions .icon-button")
        assert (
            any(
                font["isCustomFont"]
                and font["familyName"].startswith("Noto Sans Symbols")
                for font in fonts
            )
            is True
        )
        clock = bounds(page.locator(".local-clock"))
        button = bounds(theme_button)
        assert (
            abs(clock["y"] + clock["height"] / 2 - button["y"] - button["height"] / 2)
            < 1
        )
        page.screenshot(
            path=f"test-results/symbols-{preference}.png", animations="disabled"
        )
        if preference != "dark":
            theme_button.click()
    icon = bounds(page.locator(".search-launch .search-icon"))
    label = bounds(page.locator(".search-launch > span:not(.symbol)"))
    assert abs(icon["y"] + icon["height"] / 2 - label["y"] - label["height"] / 2) < 1
    for width in [390, 320]:
        page.set_viewport_size({"width": width, "height": 844})
        expect(theme_button).to_be_visible()
        expect(page.locator(".local-clock")).to_be_visible()
        assert (
            page.evaluate("() => document.documentElement.scrollWidth <= innerWidth")
            is True
        )
