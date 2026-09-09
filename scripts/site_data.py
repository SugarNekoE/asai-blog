import json
from pathlib import Path
from typing import TypedDict, cast

type JsonValue = (
    None | bool | int | float | str | list[JsonValue] | dict[str, JsonValue]
)


class Post(TypedDict):
    title: str
    description: str
    searchText: str
    date: str
    url: str
    category: str
    tags: list[str]
    readingMinutes: int


class Index(TypedDict):
    version: int
    posts: list[Post]


def required_string(data: dict[str, JsonValue], key: str) -> str:
    value = data.get(key)
    assert isinstance(value, str) and value, f"Invalid {key}"
    return value


def read_post(value: JsonValue) -> Post:
    assert isinstance(value, dict), "Post must be an object"
    raw_tags = value.get("tags")
    assert isinstance(raw_tags, list), "Tags must be a list"
    tags: list[str] = []
    for tag in raw_tags:
        assert isinstance(tag, str), "Tags must contain strings"
        tags.append(tag)
    minutes = value.get("readingMinutes")
    assert (
        isinstance(minutes, int) and not isinstance(minutes, bool) and minutes >= 1
    ), "Invalid readingMinutes"
    return {
        "title": required_string(value, "title"),
        "description": required_string(value, "description"),
        "searchText": required_string(value, "searchText"),
        "date": required_string(value, "date"),
        "url": required_string(value, "url"),
        "category": required_string(value, "category"),
        "tags": tags,
        "readingMinutes": minutes,
    }


def read_index(path: Path) -> Index:
    data = cast(JsonValue, json.loads(path.read_text(encoding="utf-8")))
    assert isinstance(data, dict), "Index must be an object"
    version = data.get("version")
    assert (
        isinstance(version, int) and not isinstance(version, bool) and version == 2
    ), "Unsupported index version"
    posts = data.get("posts")
    assert isinstance(posts, list), "Posts must be a list"
    return {"version": version, "posts": [read_post(post) for post in posts]}
