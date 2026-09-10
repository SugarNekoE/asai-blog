import os
from collections.abc import Iterator
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from threading import Thread
from typing import override

import pytest


class SiteHandler(SimpleHTTPRequestHandler):
    @override
    def log_message(self, format: str, *args: object) -> None:
        pass


@pytest.fixture(scope="session")
def base_url() -> Iterator[str]:
    site = Path(__file__).resolve().parents[1] / "_site"
    if not (site / "index.html").is_file():
        raise pytest.UsageError(
            "Build the site with just build before running browser tests"
        )
    server = ThreadingHTTPServer(
        ("127.0.0.1", 0), partial(SiteHandler, directory=str(site))
    )
    thread = Thread(
        target=server.serve_forever, kwargs={"poll_interval": 0.05}, daemon=True
    )
    thread.start()
    try:
        yield f"http://127.0.0.1:{server.server_port}"
    finally:
        server.shutdown()
        server.server_close()
        thread.join()


@pytest.fixture(scope="session")
def browser_type_launch_args(
    browser_type_launch_args: dict[str, object], browser_name: str
) -> dict[str, object]:
    arguments = dict(browser_type_launch_args)
    executable = os.environ.get("CHROMIUM_PATH")
    if executable and browser_name == "chromium":
        arguments["executable_path"] = executable
    return arguments


@pytest.fixture(scope="session")
def browser_context_args(
    browser_context_args: dict[str, object], base_url: str
) -> dict[str, object]:
    return {
        **browser_context_args,
        "base_url": base_url,
        "viewport": {"width": 1280, "height": 720},
    }


@pytest.fixture(scope="session", autouse=True)
def artifact_directory() -> None:
    Path("test-results").mkdir(exist_ok=True)
