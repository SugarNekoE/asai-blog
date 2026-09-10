{-# LANGUAGE OverloadedStrings #-}

module Site.Styles.Code (styles) where

import Clay
import qualified Clay.Media as Media
import Clay.Stylesheet (Feature (..))
import Site.Styles.Theme (token)

styles :: Css
styles = do
  ".prose code" ? do
    "font" -: "12px/1.8 var(--mono)"
    backgroundColor (token "surface")
    color (token "inline-code-color")
    padding (px 3) (px 5) (px 3) (px 5)
    borderRadius (px 3) (px 3) (px 3) (px 3)
  ".prose pre" ? do
    backgroundColor (token "sidebar")
    border (px 1) solid (token "border")
    padding (px 22) (px 22) (px 22) (px 22)
    borderRadius (px 6) (px 6) (px 6) (px 6)
    overflowX auto
    lineHeight (unitless 1.75)
  ".prose pre code" ? do
    padding (unitless 0) (unitless 0) (unitless 0) (unitless 0)
    "background" -: "none"
    color (token "text")
    whiteSpace (other "pre")
  ".prose pre a" ? do
    color (other "inherit")
  ".code-block" ? do
    minWidth (unitless 0)
    margin (em 1.3) (unitless 0) (em 1.3) (unitless 0)
    border (px 1) solid (token "border")
    borderRadius (px 6) (px 6) (px 6) (px 6)
    backgroundColor (token "sidebar")
  ".code-toolbar" ? do
    display flex
    alignItems center
    justifyContent spaceBetween
    "gap" -: "16px"
    minHeight (px 44)
    padding (px 8) (px 14) (px 8) (px 20)
    borderBottom (px 1) solid (token "border")
    color (token "muted")
    "font" -: "11px/1.6 var(--mono)"
  ".code-language" ? do
    minWidth (unitless 0)
    "overflow-wrap" -: "anywhere"
  ".code-copy" ? do
    display none
    flexShrink 0
    padding (px 5) (px 9) (px 5) (px 9)
    borderRadius (px 4) (px 4) (px 4) (px 4)
    opacity 0
    "pointer-events" -: "none"
  "code-copy[data-ready] .code-copy" ? do
    display inlineBlock
  ".code-block:hover .code-copy, .code-block:focus-within .code-copy, .code-copy[data-state]" ? do
    opacity 1
    "pointer-events" -: "auto"
  ".code-copy:hover" ? do
    backgroundColor (token "surface")
  ".code-block > .sourceCode" ? do
    margin (unitless 0) (unitless 0) (unitless 0) (unitless 0)
  ".prose .code-block pre" ? do
    margin (unitless 0) (unitless 0) (unitless 0) (unitless 0)
    padding (px 12) (px 20) (px 20) (px 20)
    "border" -: "0"
    borderRadius (unitless 0) (unitless 0) (unitless 0) (unitless 0)
    "background" -: "none"
  query Media.all [Feature "hover" (Just "none")] $ do
    ".code-copy" ? do
      minHeight (px 40)
      opacity 1
      "pointer-events" -: "auto"
  query Media.all [Feature "pointer" (Just "coarse")] $ do
    ".code-copy" ? do
      minHeight (px 40)
      opacity 1
      "pointer-events" -: "auto"
  ".sourceCode .kw, .sourceCode .cf" ? do
    color (token "syntax-keyword")
  ".sourceCode .dt, .sourceCode .ot" ? do
    color (token "syntax-type")
  ".sourceCode .st, .sourceCode .ch" ? do
    color (token "syntax-string")
  ".sourceCode .dv, .sourceCode .bn, .sourceCode .fl" ? do
    color (token "syntax-number")
  ".sourceCode .co" ? do
    color (token "syntax-comment")
    fontStyle italic
  ".sourceCode .fu" ? do
    color (token "syntax-function")
