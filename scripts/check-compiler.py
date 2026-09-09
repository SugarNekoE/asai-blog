"""Exercise authoring boundaries in a disposable vault, using the real compiler."""

import shutil
import subprocess
import tempfile
from pathlib import Path

from site_data import read_index

ROOT = Path(__file__).resolve().parent.parent


def compiler_binary() -> Path:
    if (
        subprocess.run(["ghc-pkg", "latest", "hakyll"], capture_output=True).returncode
        == 0
    ):
        return ROOT / ".build/site"
    return Path(
        subprocess.check_output(
            ["cabal", "list-bin", "site"], cwd=ROOT, text=True
        ).strip()
    )


BINARY = compiler_binary()

with tempfile.TemporaryDirectory(prefix="asai-compiler-") as temporary:
    vault = Path(temporary)
    shutil.copytree(ROOT / "templates", vault / "templates")
    (vault / "content/posts/编程/nested").mkdir(parents=True)
    (vault / "content/attachments").mkdir(parents=True)
    (vault / "content/attachments/diagram.svg").write_text(
        '<svg xmlns="http://www.w3.org/2000/svg"/>'
    )
    note = vault / "content/posts/编程/nested/fixture.md"
    source = """---
title: '中文 & "types"'
description: 'Unicode stays intact: λ → 中文.'
date: 2026-09-08
tags: ["c++", "中文"]
category: ignored-metadata
status: published
---

## Hello world

中文, λ, and an apostrophe: you're here.

[[fixture#Hello world|Self link]]
![[diagram.svg]]
[External Markdown](https://example.com/guide.md)
[Attachment](../../../attachments/diagram.svg)

```python
print('<tag> & "quotes" 中文')
```

```frobnicate
unchanged code
```

```
plain code
```
"""
    note.write_text(source)

    def build(success: bool = True) -> str:
        result = subprocess.run(
            [str(BINARY), "rebuild"], cwd=vault, text=True, capture_output=True
        )
        assert (result.returncode == 0) == success, result.stdout + result.stderr
        return result.stdout + result.stderr

    build()
    index = read_index(vault / "_site/api/posts.json")
    post = index["posts"][0]
    assert post["title"] == '中文 & "types"'
    assert "中文" in post["searchText"] and "λ" in post["searchText"]
    assert post["tags"] == ["c++", "中文"]
    assert post["category"] == "编程"
    html = (vault / "_site/posts/fixture/index.html").read_text()
    assert "中文 &amp; &quot;types&quot;" in html
    assert 'href="/posts/fixture/index.html#hello-world"' in html
    assert 'src="/attachments/diagram.svg"' in html
    assert 'href="https://example.com/guide.md"' in html
    assert 'href="/attachments/diagram.svg"' in html
    assert 'data-category="编程"' in html
    assert html.count('class="code-block"') == 3
    for language in ["python", "frobnicate", "text"]:
        assert f'class="code-language">{language}</span>' in html
    assert "&lt;tag&gt;" in html
    assert "frobnicate" not in post["searchText"]
    assert "plain code" in post["searchText"]

    (vault / "content/posts/moved").mkdir()
    moved = vault / "content/posts/moved/fixture.md"
    note.rename(moved)
    note = moved
    build()
    moved_post = read_index(vault / "_site/api/posts.json")["posts"][0]
    assert moved_post["category"] == "moved"
    assert moved_post["url"] == post["url"]

    note.write_text(source.replace("status: published", "status: draft"))
    build()
    assert not (vault / "_site/posts/fixture/index.html").exists()
    assert read_index(vault / "_site/api/posts.json")["posts"] == []

    public = vault / "content/posts/moved/public.md"
    public.write_text(
        source.replace("[[fixture#Hello world|Self link]]", "[[fixture]]")
    )
    assert "unpublished note" in build(success=False)
    public.unlink()
    note.write_text(source.replace("![[diagram.svg]]", "![[missing.svg]]"))
    assert "Missing attachment" in build(success=False)

    note.write_text(source)
    note.rename(vault / "content/posts/fixture.md")
    assert "Post must be inside a category folder" in build(success=False)

print(
    "Verified folder categories, category moves, uncategorized rejection, Unicode/escaping, wiki links, embeds, external links, unpublishing, and private/missing targets."
)
