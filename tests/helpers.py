from collections.abc import Callable, Generator
from contextlib import contextmanager
from typing import TypedDict
from urllib.parse import parse_qs, urlsplit

from playwright.sync_api import Locator, Page, Route


class Bounds(TypedDict):
    x: float
    y: float
    width: float
    height: float


def bounds(locator: Locator) -> Bounds:
    result = locator.bounding_box()
    assert result is not None, "Expected a rendered element with a bounding box"
    return result


def content_text(locator: Locator) -> str:
    result = locator.text_content()
    assert result is not None
    return result


def attribute(locator: Locator, name: str) -> str:
    result = locator.get_attribute(name)
    assert result is not None, f"Missing {name} attribute"
    return result


def query_params(url: str) -> dict[str, list[str]]:
    return parse_qs(urlsplit(url).query, keep_blank_values=True)


def query_param(url: str, name: str) -> str | None:
    return next(iter(query_params(url).get(name, [])), None)


class RequestGate:
    def __init__(self) -> None:
        self._released = False
        self._pending: list[Route] = []

    def handle(self, route: Route) -> None:
        if self._released:
            route.continue_()
        else:
            self._pending.append(route)

    def release(self) -> None:
        self._released = True
        pending, self._pending = self._pending, []
        for route in pending:
            route.continue_()


@contextmanager
def hold_requests(page: Page, pattern: str) -> Generator[RequestGate]:
    gate = RequestGate()
    page.route(pattern, gate.handle)
    try:
        yield gate
    finally:
        gate.release()
        page.unroute(pattern, gate.handle)


def fulfill_json(payload: object) -> Callable[[Route], None]:
    return lambda route: route.fulfill(json=payload)
