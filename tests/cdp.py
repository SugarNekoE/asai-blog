import base64
from pathlib import Path
from typing import Protocol, TypedDict, cast

from playwright.sync_api import Page


class DevTools(Protocol):
    def send(
        self, method: str, params: dict[str, object] | None = None
    ) -> dict[str, object]: ...
    def detach(self) -> None: ...


class Node(TypedDict):
    nodeId: int


class Document(TypedDict):
    root: Node


class Font(TypedDict):
    isCustomFont: bool
    familyName: str


class Fonts(TypedDict):
    fonts: list[Font]


def session(page: Page) -> DevTools:
    return cast(DevTools, page.context.new_cdp_session(page))


def platform_fonts(page: Page, selector: str) -> list[Font]:
    client = session(page)
    try:
        client.send("DOM.enable")
        client.send("CSS.enable")
        document = cast(Document, client.send("DOM.getDocument"))
        node = cast(
            Node,
            client.send(
                "DOM.querySelector",
                {"nodeId": document["root"]["nodeId"], "selector": selector},
            ),
        )
        result = cast(
            Fonts,
            client.send("CSS.getPlatformFontsForNode", {"nodeId": node["nodeId"]}),
        )
        return result["fonts"]
    finally:
        client.detach()


def capture_loading(page: Page, path: str) -> None:
    # Playwright screenshots wait for fonts; CDP can capture the font-loading screen.
    client = session(page)
    try:
        data = client.send("Page.captureScreenshot", {"format": "png"})["data"]
        assert isinstance(data, str)
        Path(path).write_bytes(base64.b64decode(data))
    finally:
        client.detach()
