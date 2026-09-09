import argparse
from pathlib import Path

from fontTools import subset
from fontTools.ttLib import TTFont


def build_font(source, family, stem, style="normal", collection=None):
    options = subset.Options()
    options.layout_features = ["*"]
    options.name_IDs = ["*"]
    options.name_legacy = True
    options.name_languages = ["*"]
    font = TTFont(source, fontNumber=collection if collection is not None else -1)
    codepoints = set(font.getBestCmap())
    weights = next(axis for axis in font["fvar"].axes if axis.axisTag == "wght")
    groups = (
        sorted({point // 2048 for point in codepoints})
        if collection is not None
        else [None]
    )
    rules = []
    for group in groups:
        selected = (
            {point for point in codepoints if point // 2048 == group}
            if group is not None
            else codepoints
        )
        part = TTFont(source, fontNumber=collection if collection is not None else -1)
        subsetter = subset.Subsetter(options=options)
        subsetter.populate(unicodes=selected)
        subsetter.subset(part)
        filename = f"{stem}{f'-{group:03x}' if group is not None else ''}.woff2"
        part.flavor = "woff2"
        part.save(OUTPUT / filename)
        part.close()
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
    font.close()
    print(f"{family} ({style}): {len(groups)} WOFF2 files", flush=True)
    return rules


OUTPUT = Path(__file__).resolve().parent.parent / "static/assets/fonts"


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("noto", type=Path, help="Directory containing NotoSans.ttf")
    parser.add_argument(
        "cjk", type=Path, help="Directory containing Noto CJK variable TTCs"
    )
    args = parser.parse_args()
    rules = []
    for filename, family, style in [
        ("NotoSans", "Noto Sans", "normal"),
        ("NotoSans-Italic", "Noto Sans", "italic"),
        ("NotoSansMono", "Noto Sans Mono", "normal"),
    ]:
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
