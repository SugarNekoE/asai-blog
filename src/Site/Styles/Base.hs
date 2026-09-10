{-# LANGUAGE OverloadedStrings #-}

module Site.Styles.Base (styles) where

import Clay
import qualified Clay.Media as Media
import Clay.Stylesheet (Feature (..))
import Site.Styles.Theme (token)

styles :: Css
styles = do
  "*" ? do
    boxSizing borderBox
  "html" ? do
    "scroll-behavior" -: "smooth"
    "scroll-padding-top" -: "30px"
  "body" ? do
    margin (unitless 0) (unitless 0) (unitless 0) (unitless 0)
    backgroundColor (token "bg")
    color (token "text")
    "font" -: "15px/1.65 var(--sans)"
  "a" ? do
    color (other "inherit")
    textDecoration none
  "button, input" ? do
    "font" -: "inherit"
  "button" ? do
    cursor pointer
    color (other "inherit")
  "button, a, input" ? do
    "touch-action" -: "manipulation"
  "button" ? do
    "border" -: "0"
    "background" -: "none"
  "button:hover, a:hover" ? do
    color (token "accent")
  ":focus-visible" ? do
    "outline" -: "2px solid var(--accent)"
    "outline-offset" -: "4px"
  "html.focus-managed :focus-visible:not([data-tab-focus])" ? do
    "outline" -: "none"
  "::selection" ? do
    backgroundColor (token "selection-color")
  "button:disabled" ? do
    "cursor" -: "default"
  "h1, h2, h3, p" ? do
    marginTop (unitless 0)
  "a, button" ? do
    "transition" -: "color 0.15s, background 0.15s"
  ".muted" ? do
    color (token "muted")
  ".accent" ? do
    color (token "accent")
  ".brand" ? do
    display flex
    alignItems center
    "gap" -: "13px"
    fontSize (px 25)
    fontWeight (weight 650)
    letterSpacing (px (-1))
    margin (unitless 0) (px 9) (px 31) (px 9)
  ".brand-mark" ? do
    "font" -: "40px/1 var(--mono)"
    color (token "accent")
  ".brand small" ? do
    display block
    "font" -: "9px/1.8 var(--mono)"
    color (token "muted")
    letterSpacing (px 2.6)
    marginTop (px 3)
  "html.search-open" ? do
    overflow hidden
  "kbd" ? do
    "font" -: "10px var(--mono)"
    border (px 1) solid (token "border")
    borderRadius (px 3) (px 3) (px 3) (px 3)
    padding (px 2) (px 6) (px 2) (px 6)
    color (token "faint")
  ".eyebrow" ? do
    "font" -: "10px/1.6 var(--mono)"
    letterSpacing (px 1.6)
    color (token "muted")
  "blog-content" ? do
    display block
  ".fallback" ? do
    maxWidth (px 950)
    margin auto auto auto auto
    padding (px 35) (px 35) (px 35) (px 35)
  ".fallback nav" ? do
    display flex
    alignItems center
    "gap" -: "25px"
    marginBottom (px 60)
  ".fallback nav .brand" ? do
    margin (unitless 0) auto (unitless 0) (unitless 0)
    fontSize (px 20)
  ".fallback footer" ? do
    marginTop (px 50)
    "font" -: "11px var(--mono)"
    color (token "muted")
  ".fallback .post-row h2" ? do
    fontSize (px 22)
  ".fallback .post-row p" ? do
    color (token "muted")
  query Media.all [Feature "max-width" (Just "760px")] $ do
    ".fallback" ? do
      padding (px 24) (px 24) (px 24) (px 24)
  query Media.all [Feature "max-width" (Just "760px")] $ do
    ".fallback nav" ? do
      "gap" -: "15px"
  query Media.all [Feature "max-width" (Just "760px")] $ do
    ".fallback nav .muted" ? do
      display none
  query Media.all [Feature "prefers-reduced-motion" (Just "reduce")] $ do
    "html" ? do
      "scroll-behavior" -: "auto"
  query Media.all [Feature "prefers-reduced-motion" (Just "reduce")] $ do
    "*" ? do
      important $ "transition" -: "none"
  query Media.all [Feature "prefers-reduced-motion" (Just "reduce")] $ do
    "*::before" ? do
      important $ "transition" -: "none"
  query Media.all [Feature "prefers-reduced-motion" (Just "reduce")] $ do
    "*::after" ? do
      important $ "transition" -: "none"
  ".fallback .post-row" ? do
    "display" -: "grid"
    "grid-template-columns" -: "80px minmax(0, 1fr)"
    "gap" -: "24px"
    padding (px 24) (unitless 0) (px 24) (unitless 0)
    borderBottom (px 1) solid (token "border")
  ".fallback .intro" ? do
    padding (px 40) (unitless 0) (px 40) (unitless 0)
