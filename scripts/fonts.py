import argparse
from pathlib import Path
from typing import Literal

from fontTools import subset
from fontTools.ttLib import TTFont


def build_font(
    source: Path,
    family: str,
    stem: str,
    style: Literal["normal", "italic"] = "normal",
    collection: int | None = None,
) -> list[str]:
    options = subset.Options()
    options.layout_features = ["*"]
    options.name_IDs = ["*"]
    options.name_legacy = True
    options.name_languages = ["*"]
    with TTFont(
        source, fontNumber=collection if collection is not None else -1
    ) as font:
        cmap = font.getBestCmap()
        if not cmap:
            raise ValueError(f"Font has no Unicode character map: {source}")
        codepoints = set(cmap)
        weights = next(
            (axis for axis in font["fvar"].axes if axis.axisTag == "wght"), None
        )
        if weights is None:
            raise ValueError(f"Font has no variable weight axis: {source}")
    groups: list[int] | list[None] = [None]
    if collection is not None:
        groups = sorted({point // 2048 for point in codepoints})
    rules: list[str] = []
    for group in groups:
        selected = (
            {point for point in codepoints if point // 2048 == group}
            if group is not None
            else codepoints
        )
        filename = f"{stem}{f'-{group:03x}' if group is not None else ''}.woff2"
        with TTFont(
            source, fontNumber=collection if collection is not None else -1
        ) as part:
            subsetter = subset.Subsetter(options=options)
            subsetter.populate(unicodes=selected)
            subsetter.subset(part)
            part.flavor = "woff2"
            part.save(OUTPUT / filename)
        rule = [
            "@font-face {",
            f"  font-family: '{family}';",
            f"  src: url('/assets/fonts/{filename}') format('woff2');",
            f"  font-style: {style};",
            f"  font-weight: {weights.minValue:g} {weights.maxValue:g};",
            "  font-display: swap;",
        ]
        if group is not None:
            rule.append(f"  unicode-range: U+{min(selected):X}-{max(selected):X};")
        rules.append("\n".join([*rule, "}"]))
    print(f"{family} ({style}): {len(groups)} WOFF2 files", flush=True)
    return rules


OUTPUT = Path(__file__).resolve().parent.parent / "static/assets/fonts"


class FontArguments(argparse.Namespace):
    def __init__(self) -> None:
        super().__init__()
        self.noto = Path()
        self.cjk = Path()


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("noto", type=Path, help="Directory containing NotoSans.ttf")
    parser.add_argument(
        "cjk", type=Path, help="Directory containing Noto CJK variable TTCs"
    )
    args = parser.parse_args(namespace=FontArguments())
    rules: list[str] = []
    text_fonts: list[tuple[str, str, Literal["normal", "italic"]]] = [
        ("NotoSans", "Noto Sans", "normal"),
        ("NotoSans-Italic", "Noto Sans", "italic"),
        ("NotoSansMono", "Noto Sans Mono", "normal"),
    ]
    for filename, family, style in text_fonts:
        rules.extend(build_font(args.noto / f"{filename}.ttf", family, filename, style))
    for filename, family in [
        ("NotoSansCJK", "Noto Sans CJK SC"),
        ("NotoSansMonoCJK", "Noto Sans Mono CJK SC"),
    ]:
        rules.extend(
            build_font(
                args.cjk / f"{filename}-VF.otf.ttc",
                family,
                f"{filename}sc",
                collection=2,
            )
        )
    (OUTPUT.parent / "noto.css").write_text("\n\n".join(rules) + "\n")


if __name__ == "__main__":
    main()
