{-# LANGUAGE OverloadedStrings #-}

module Site.Styles.Print (styles) where

import Clay
import qualified Clay.Selector as Selector
import Site.Styles.Theme (token)

styles :: Css
styles = do
  Selector.element "@page" ? do
    "size" -: "A4"
    margin (mm 12) (mm 14) (mm 12) (mm 14)
  ":root, :root[data-theme]" ? do
    "color-scheme" -: "light"
    "--bg" -: "var(--print-paper)"
    "--sidebar" -: "var(--print-paper)"
    "--surface" -: "var(--print-paper)"
    "--hover" -: "var(--print-paper)"
    "--text" -: "var(--print-text)"
    "--muted" -: "var(--print-muted)"
    "--faint" -: "var(--print-muted)"
    "--border" -: "var(--print-border)"
    "--accent" -: "var(--print-text)"
    "--category-color" -: "var(--print-muted)"
    "--quote-color" -: "var(--print-border)"
    "--inline-code-color" -: "var(--print-text)"
    "--syntax-keyword" -: "var(--print-text)"
    "--syntax-type" -: "var(--print-text)"
    "--syntax-string" -: "var(--print-text)"
    "--syntax-number" -: "var(--print-text)"
    "--syntax-comment" -: "var(--print-muted)"
    "--syntax-function" -: "var(--print-text)"
  "*" ? do
    important $ "box-shadow" -: "none"
    important $ "text-shadow" -: "none"
    important $ "outline" -: "none"
    important $ "animation" -: "none"
    important $ "transition" -: "none"
  "html, body" ? do
    important $ backgroundColor (token "print-paper")
    important $ color (token "print-text")
    "font" -: "10.5pt/1.5 var(--sans)"
    "print-color-adjust" -: "economy"
  "html, body, #app, .workspace, .editor, .main-content, .page-content, .fallback, #static-content, blog-content, .prose" ? do
    important $ display block
    important $ position static
    important $ width auto
    important $ minWidth (unitless 0)
    important $ maxWidth none
    important $ height auto
    important $ minHeight (unitless 0)
    important $ maxHeight none
    important $ margin (unitless 0) (unitless 0) (unitless 0) (unitless 0)
    important $ padding (unitless 0) (unitless 0) (unitless 0) (unitless 0)
    important $ overflow visible
    important $ visibility visible
  ".sidebar, .topbar, .immersive-header, .code-toolbar, .statusbar, .page-outline, .skip-link, .link-hints, #loading-screen, dialog, .filterbar, .search-field, .pagination, .notebook-end, .intro-meta, .prose > .back, .article-end-divider, .end-note, .post-arrow, .empty-state button, .fallback > nav, .fallback > footer, .collection-header .eyebrow" ? do
    important $ display none
  "dialog::backdrop" ? do
    important $ display none
    important $ "background" -: "none"
  ".prose" ? do
    important $ fontSize (pt 10.5)
    important $ lineHeight (unitless 1.5)
    "overflow-wrap" -: "anywhere"
  ".article-header" ? do
    important $ margin (unitless 0) (unitless 0) (pt 16) (unitless 0)
    "break-inside" -: "avoid"
  ".article-header h1, .prose > h1, .intro h1" ? do
    margin (pt 6) (unitless 0) (pt 10) (unitless 0)
    fontSize (pt 23)
    lineHeight (unitless 1.2)
    letterSpacing (pt (-0.5))
  ".article-header .eyebrow" ? do
    fontSize (pt 8)
    letterSpacing (pt 0.5)
  ".article-header .dek" ? do
    fontSize (pt 11)
    lineHeight (unitless 1.5)
  ".prose h2" ? do
    margin (pt 16) (unitless 0) (pt 7) (unitless 0)
    fontSize (pt 15)
    lineHeight (unitless 1.3)
  ".prose h3" ? do
    margin (pt 12) (unitless 0) (pt 6) (unitless 0)
    fontSize (pt 12)
    lineHeight (unitless 1.3)
  "h1, h2, h3, h4, h5, h6" ? do
    "break-after" -: "avoid"
  "p, li" ? do
    "orphans" -: "3"
    "widows" -: "3"
  ".prose p" ? do
    margin (unitless 0) (unitless 0) (pt 9) (unitless 0)
  "a" ? do
    important $ color (token "print-text")
    textDecoration underline
    "overflow-wrap" -: "anywhere"
  ".prose blockquote" ? do
    margin (pt 12) (unitless 0) (pt 12) (unitless 0)
    padding (pt 4) (pt 10) (pt 4) (pt 10)
    borderLeft (pt 1) solid (token "print-border")
    "background" -: "none"
  ".prose code" ? do
    padding (unitless 0) (unitless 0) (unitless 0) (unitless 0)
    "background" -: "none"
    "font" -: "9pt/1.4 var(--mono)"
  ".code-block" ? do
    margin (em 1) (unitless 0) (em 1) (unitless 0)
    "border" -: "0"
    "background" -: "none"
  ".prose pre, .prose .code-block pre" ? do
    padding (pt 9) (pt 9) (pt 9) (pt 9)
    border (pt 0.5) solid (token "print-border")
    borderRadius (unitless 0) (unitless 0) (unitless 0) (unitless 0)
    "background" -: "none"
    "break-inside" -: "auto"
  ".prose pre, .prose pre code, .prose .sourceCode" ? do
    maxWidth (pct 100)
    important $ overflow visible
    important $ whiteSpace preWrap
    "overflow-wrap" -: "anywhere"
    "word-break" -: "normal"
    "tab-size" -: "4"
  ".prose table" ? do
    display (other "table")
    width (pct 100)
    "table-layout" -: "fixed"
    "border-collapse" -: "collapse"
    overflow visible
    fontSize (pt 9)
    "break-inside" -: "auto"
  ".prose th, .prose td" ? do
    padding (pt 5) (pt 6) (pt 5) (pt 6)
    border (pt 0.5) solid (token "print-border")
    "background" -: "none"
    "overflow-wrap" -: "anywhere"
  "thead" ? do
    "display" -: "table-header-group"
  "tfoot" ? do
    "display" -: "table-footer-group"
  "tr" ? do
    "break-inside" -: "avoid"
  ".prose figure, .prose img, .prose svg" ? do
    maxWidth (pct 100)
    "break-inside" -: "avoid"
  ".prose figure" ? do
    margin (pt 12) (unitless 0) (pt 12) (unitless 0)
  ".prose img" ? do
    maxHeight (mm 240)
    "object-fit" -: "contain"
  ".post-list" ? do
    display block
  ".post-row" ? do
    display block
    padding (pt 10) (unitless 0) (pt 10) (unitless 0)
    "break-inside" -: "avoid"
  ".post-row h2, .post-row h3" ? do
    margin (pt 4) (unitless 0) (pt 4) (unitless 0)
    fontSize (pt 14)
  ".post-row p" ? do
    maxWidth none
    fontSize (pt 10)
  ".tag[data-tag]" ? do
    "--tag-color" -: "var(--print-muted)"
    padding (unitless 0) (unitless 0) (unitless 0) (unitless 0)
    "border" -: "0"
    important $ "background" -: "none"
