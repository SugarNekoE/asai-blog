import re
import subprocess

from playwright.sync_api import Browser, Page, expect

from tests.helpers import (
    hold_requests,
)


def test_print_output_contains_the_article_without_panels_controls_or_a_dark_canvas(
    page: Page,
) -> None:
    page.goto("/posts/plain-text-to-a-small-web/")
    expect(page.locator(".workspace")).to_be_visible()
    page.keyboard.press("?")
    expect(page.locator("#keymap-dialog")).to_be_visible()
    page.emulate_media(media="print")
    for selector in [
        ".sidebar",
        ".topbar",
        ".statusbar",
        ".page-outline",
        "#keymap-dialog",
        ".prose > .back",
        ".end-note",
        ".article-end-divider",
    ]:
        expect(page.locator(selector)).to_be_hidden()
    expect(page.locator(".prose h1")).to_be_visible()
    expect(page.locator("body")).to_have_css("background-color", "rgb(255, 255, 255)")
    expect(page.locator("html")).to_have_css("overflow", "visible")
    expect(page.locator(".prose")).to_have_css("color", "rgb(0, 0, 0)")
    page.evaluate("() => document.fonts.ready")
    path = "test-results/article-print.pdf"
    page.pdf(path=path, prefer_css_page_size=True, print_background=True)
    text = re.sub(re.compile("\\s+"), " ", pdf_text(path))
    assert "From plain text to a small, personal web" in text
    assert "Keep the build disposable" in text
    for chrome in [
        "Keyboard shortcuts",
        "ON THIS PAGE",
        "RSS feed",
        "CC-BY-SA",
        "End of file. Keep exploring.",
        "Please Be Patient",
    ]:
        assert chrome not in text
    assert not re.search(re.compile("loading \\d+ms"), text)
    assert "A4" in subprocess.check_output(["pdfinfo", path], text=True)
    page.emulate_media(media="screen")
    expect(page.locator("#keymap-dialog")).to_be_visible()
    expect(page.locator("body")).to_have_css("background-color", "rgb(36, 34, 37)")


def test_long_code_and_tables_print_completely_across_multiple_pages_in_immersive_mode(
    page: Page,
) -> None:
    page.goto("/posts/plain-text-to-a-small-web/")
    expect(page.locator(".workspace")).to_be_visible()
    page.keyboard.press("Shift+I")
    page.evaluate(r"""() => {
      const article = document.querySelector('.prose');
      const pre = document.createElement('pre');
      const code = document.createElement('code');
      code.textContent =
        Array.from(
          { length: 50 },
          (_, index) => `line_${index}: ` + 'UNBROKEN_IDENTIFIER_'.repeat(18),
        ).join('\n') + '\nPRINT_CODE_END';
      pre.append(code);
      article.append(pre);
      const table = document.createElement('table');
      const head = table.createTHead().insertRow();
      for (let column = 0; column < 8; column++) {
        const cell = document.createElement('th');
        cell.textContent = `Column ${column}`;
        head.append(cell);
      }
      const body = table.createTBody();
      for (let row = 0; row < 60; row++) {
        const line = body.insertRow();
        for (let column = 0; column < 8; column++)
          line.insertCell().textContent = `value_${row}_${column}_long`;
      }
      const end = body.insertRow().insertCell();
      end.colSpan = 8;
      end.textContent = 'PRINT_TABLE_END';
      article.append(table);
      const last = document.createElement('p');
      last.textContent = 'PRINT_ARTICLE_END';
      article.append(last);
    }""")
    page.emulate_media(media="print")
    expect(page.locator(".main-content")).to_have_css("padding-left", "0px")
    expect(page.locator(".immersive-header")).to_be_hidden()
    expect(page.locator(".prose pre").last).to_have_css("overflow", "visible")
    expect(page.locator(".prose table")).to_have_css("display", "table")
    expect(page.locator("thead")).to_have_css("display", "table-header-group")
    page.evaluate("() => document.fonts.ready")
    path = "test-results/article-long-print.pdf"
    page.pdf(path=path, prefer_css_page_size=True, print_background=True)
    text = pdf_text(path)
    assert (
        len(
            re.findall(
                re.compile("UNBROKEN_IDENTIFIER_"), re.sub(re.compile("\\s+"), "", text)
            )
        )
        == 900
    )
    assert len(re.findall(re.compile("value_"), text)) == 480
    for marker in ["PRINT_CODE_END", "PRINT_TABLE_END", "PRINT_ARTICLE_END"]:
        assert marker in text
    assert len(text.split("\x0c")) - 1 > 1
    page.emulate_media(media="screen")
    expect(page.locator(".workspace")).to_have_class(re.compile("is-immersive"))


def test_printing_works_with_javascript_disabled_and_hides_index_controls(
    browser: Browser, page: Page, base_url: str
) -> None:
    context = browser.new_context(base_url=base_url, java_script_enabled=False)
    try:
        static_page = context.new_page()
        static_page.goto("/posts/types-as-design-tools/")
        static_page.emulate_media(media="print")
        expect(static_page.locator(".fallback > nav")).to_be_hidden()
        expect(static_page.locator(".fallback > footer")).to_be_hidden()
        expect(static_page.locator(".prose h1")).to_be_visible()
        path = "test-results/article-static-print.pdf"
        static_page.pdf(path=path, prefer_css_page_size=True)
        assert "Types are a way to ask better questions" in re.sub(
            re.compile("\\s+"), " ", pdf_text(path)
        )
    finally:
        context.close()
    page.goto("/?tag=elm")
    expect(page.locator(".post-row")).to_have_count(1)
    page.emulate_media(media="print")
    for selector in [".filterbar", ".search-field", ".pagination", ".notebook-end"]:
        expect(page.locator(selector)).to_be_hidden()
    expect(page.locator(".post-row")).to_be_visible()


def pdf_text(path: str) -> str:
    return subprocess.check_output(["pdftotext", path, "-"], text=True)


def test_print_styles_reveal_static_content_even_during_startup(page: Page) -> None:
    with hold_requests(page, "**/assets/elm.js*") as script:
        page.goto("/posts/types-as-design-tools/", wait_until="commit")
        expect(page.locator("#loading-screen")).to_be_visible()
        page.emulate_media(media="print")
        expect(page.locator("#loading-screen")).to_be_hidden()
        expect(page.locator("#static-content")).to_be_visible()
        page.emulate_media(media="screen")
        expect(page.locator("#loading-screen")).to_be_visible()
        script.release()
        expect(page.locator(".workspace")).to_be_visible()
