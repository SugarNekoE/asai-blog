{-# LANGUAGE OverloadedStrings #-}

module Site.Styles.Article (styles) where

import Clay
import qualified Clay.Media as Media
import Clay.Stylesheet (Feature (..))
import qualified Site.Styles.Code as Code
import Site.Styles.Theme (token)

styles :: Css
styles = do
  ".prose" ? do
    maxWidth (px 730)
    margin auto auto auto auto
    fontSize (px 16)
    lineHeight (unitless 1.9)
    "overflow-wrap" -: "break-word"
  ".back" ? do
    display block
    width (other "fit-content")
    "font" -: "11px/16px var(--mono)"
    color (token "muted")
  ".article-header" ? do
    margin (px 40) (unitless 0) (px 40) (unitless 0)
  ".article-header h1, .prose > h1" ? do
    fontSize (other "clamp(30px, 3.2vw, 45px)")
    lineHeight (unitless 1.25)
    letterSpacing (px (-1.3))
    fontWeight (weight 550)
    margin (px 16) (unitless 0) (px 20) (unitless 0)
  ".dek" ? do
    fontSize (px 17)
    color (token "muted")
    lineHeight (unitless 1.8)
  ".prose h2" ? do
    fontSize (px 25)
    fontWeight (weight 550)
    letterSpacing (px (-0.6))
    marginTop (px 45)
    lineHeight (unitless 1.4)
  ".prose h3" ? do
    fontSize (px 20)
    marginTop (px 35)
  ".prose p" ? do
    marginBottom (px 22)
  ".prose a" ? do
    color (token "accent")
    "text-underline-offset" -: "4px"
  ".prose a:hover" ? do
    textDecoration underline
  ".prose blockquote" ? do
    margin (px 25) (unitless 0) (px 25) (unitless 0)
    padding (px 10) (px 22) (px 10) (px 22)
    borderLeft (px 2) solid (token "quote-color")
    backgroundColor (token "surface")
    color (token "muted")
  ".prose blockquote p:last-child" ? do
    marginBottom (unitless 0)
  Code.styles
  ".prose img" ? do
    maxWidth (pct 100)
    height auto
    borderRadius (px 5) (px 5) (px 5) (px 5)
  ".prose table" ? do
    display block
    overflowX auto
    "border-collapse" -: "collapse"
    width (pct 100)
    fontSize (px 13)
    margin (px 25) (unitless 0) (px 25) (unitless 0)
  ".prose th, .prose td" ? do
    padding (px 10) (px 16) (px 10) (px 16)
    border (px 1) solid (token "border")
    textAlign (other "left")
  ".prose th" ? do
    backgroundColor (token "surface")
  ".prose hr" ? do
    "border" -: "0"
    borderTop (px 1) solid (token "border")
    margin (px 40) (unitless 0) (px 40) (unitless 0)
  ".end-note" ? do
    "font" -: "11px/1.8 var(--mono)"
    color (token "faint")
  query Media.all [Feature "max-width" (Just "760px")] $ do
    ".prose" ? do
      fontSize (px 15)
  query Media.all [Feature "max-width" (Just "760px")] $ do
    ".article-header" ? do
      marginTop (px 30)
