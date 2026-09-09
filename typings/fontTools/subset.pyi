from collections.abc import Iterable
from typing import Literal

from .ttLib import TTFont

class Options:
    layout_features: list[str]
    name_IDs: list[int | Literal["*"]]
    name_legacy: bool
    name_languages: list[int | Literal["*"]]

    def __init__(self) -> None: ...

class Subsetter:
    def __init__(self, options: Options | None = None) -> None: ...
    def populate(self, *, unicodes: Iterable[int]) -> None: ...
    def subset(self, font: TTFont) -> None: ...
