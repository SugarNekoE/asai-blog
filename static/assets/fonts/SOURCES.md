# Bundled Noto fonts

All fonts are served from this directory; visitors do not need Noto installed.
Only generic system fonts follow Noto in the CSS stacks.

| Family                                     | Source                                                                                                                   | License        |
| ------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------ | -------------- |
| Noto Sans, upright and italic              | [Noto Latin, Greek, Cyrillic](https://github.com/notofonts/latin-greek-cyrillic), Nix `noto-fonts` 2026.05.01            | `OFL-Sans.txt` |
| Noto Sans Mono                             | [Noto Sans Mono](https://github.com/notofonts/noto-fonts/tree/main/hinted/ttf/NotoSansMono), Nix `noto-fonts` 2026.05.01 | `OFL-Mono.txt` |
| Noto Sans CJK SC and Noto Sans Mono CJK SC | [Noto CJK Sans 2.004](https://github.com/notofonts/noto-cjk/tree/Sans2.004), Nix `noto-fonts-cjk-sans` 2.004             | `OFL-CJK.txt`  |
| Noto Sans Symbols and Symbols 2            | [Noto Symbols](https://github.com/notofonts/symbols), Nix `noto-fonts` 2026.05.01                                        | `OFL.txt`      |

Sans and Mono retain their variable weights. Sans also has a real italic face.
CJK uses the Simplified Chinese default face from the upstream pan-CJK
collections, retaining Chinese (simplified and traditional), Japanese, Korean,
variable weights, and OpenType language-specific substitutions. Mark passages
with the appropriate HTML `lang` to select localized glyphs. CJK has no upstream
italic face; browsers synthesize slanted CJK and monospace text when requested.

`scripts/fonts.py` converts text fonts to WOFF2 and partitions each CJK face into
2,048-codepoint blocks, keeping every encoded character and layout feature.
Generated `../noto.css` declares the ranges so browsers fetch only matching blocks.
Symbols are unmodified upstream files. Copyright and license records remain
embedded in the generated fonts as well as in the accompanying license files.

To regenerate using the source font directories from the versions above:

```sh
devenv shell -- just fonts /path/to/share/fonts/noto /path/to/share/fonts/opentype/noto-cjk
```

Normal site builds copy these vendored assets without regenerating them.
