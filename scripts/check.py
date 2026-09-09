"""Check the published artifact, including its Elm data contract and local links."""

import json
import re
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import unquote, urljoin, urlsplit
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parent.parent
SITE = ROOT / "_site"


class Page(HTMLParser):
    def __init__(self, text):
        super().__init__()
        self.ids = set()
        self.links = []
        self.feed(text)

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if "id" in attrs:
            self.ids.add(attrs["id"])
        for key in ("href", "src"):
            if key in attrs:
                self.links.append(attrs[key])


data = json.loads((SITE / "api/posts.json").read_text())
assert data["version"] == 2
posts = data["posts"]
assert len({post["url"] for post in posts}) == len(posts), "Duplicate post URLs"
assert [post["date"] for post in posts] == sorted(
    (p["date"] for p in posts), reverse=True
)
assert len(posts) == len(list((SITE / "posts").rglob("index.html"))), (
    "Article count differs from index"
)
for post in posts:
    for key in ("title", "description", "searchText", "date", "url", "category"):
        assert isinstance(post[key], str) and post[key], f"Invalid {key}"
    assert re.fullmatch(r"\d{4}-\d{2}-\d{2}", post["date"])
    assert isinstance(post["tags"], list) and all(
        isinstance(t, str) for t in post["tags"]
    )
    assert isinstance(post["readingMinutes"], int) and post["readingMinutes"] >= 1
    assert (SITE / post["url"].lstrip("/")).is_file()
    sources = list(
        (ROOT / "content/posts").rglob(Path(post["url"]).parent.name + ".md")
    )
    assert len(sources) == 1, "Post filenames must be unique"
    assert sources[0].relative_to(ROOT / "content/posts").parts[0] == post["category"]

pages = {path: Page(path.read_text()) for path in SITE.rglob("*.html")}
for path, page in pages.items():
    assert "static-content" in page.ids, f"Missing no-JS content: {path}"
    assert "/about/" not in path.read_text(), f"Removed About link in {path}"
    assert 'class="tabbar"' not in path.read_text()
    for link in page.links:
        url = urlsplit(urljoin("/" + str(path.relative_to(SITE)), link))
        if url.scheme or url.netloc:
            continue
        target = SITE / unquote(url.path).lstrip("/")
        if target.is_dir():
            target /= "index.html"
        assert target.is_file(), f"Broken link in {path}: {link}"
        if url.fragment and target in pages:
            assert unquote(url.fragment) in pages[target].ids, (
                f"Missing anchor in {path}: {link}"
            )

feed = ET.parse(SITE / "feed.xml")
assert len(feed.findall("{http://www.w3.org/2005/Atom}entry")) == min(20, len(posts))
for path in SITE.rglob("*"):
    if path.is_file():
        assert "PRIVATE_DRAFT_SENTINEL" not in path.read_text(errors="ignore"), (
            f"Draft content leaked: {path}"
        )
assert not (SITE / "content").exists()
assert not (SITE / ".obsidian").exists()
assert not (SITE / "about").exists()
assert (SITE / "404.html").exists()
assert (SITE / "_headers").exists()
assert (SITE / "assets/elm.js").stat().st_size > 1000, "Elm bundle is missing or empty"
print(
    f"Verified {len(posts)} published notes, {len(pages)} HTML pages, JSON schema, local links, anchors, feed, and draft exclusion."
)
