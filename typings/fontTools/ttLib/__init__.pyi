from os import PathLike
from types import TracebackType
from typing import Literal, Protocol, Self

class _Axis(Protocol):
    axisTag: str
    minValue: float
    maxValue: float

class _VariableTable(Protocol):
    axes: list[_Axis]

class TTFont:
    flavor: str | None

    def __init__(self, file: str | PathLike[str], *, fontNumber: int = -1) -> None: ...
    def __enter__(self) -> Self: ...
    def __exit__(
        self,
        exc_type: type[BaseException] | None,
        exc_value: BaseException | None,
        traceback: TracebackType | None,
    ) -> None: ...
    def __getitem__(self, tag: Literal["fvar"]) -> _VariableTable: ...
    def getBestCmap(self) -> dict[int, str] | None: ...
    def save(self, file: str | PathLike[str]) -> None: ...
    def close(self) -> None: ...
