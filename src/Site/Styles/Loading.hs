{-# LANGUAGE OverloadedStrings #-}

module Site.Styles.Loading (styles) where

import Clay
import qualified Clay.Media as Media
import Clay.Stylesheet (Feature (..))
import Site.Styles.Theme (token)

styles :: Css
styles = do
  "html.is-loading" ? do
    overflow hidden
  "html.is-loading #app, html.is-loading .workspace" ? do
    visibility hidden
  ".loading-screen" ? do
    position fixed
    "inset" -: "0"
    zIndex 50
    "display" -: "grid"
    "place-items" -: "center"
    padding (px 24) (px 24) (px 24) (px 24)
    backgroundColor (token "bg")
    color (token "text")
  ".loading-screen[hidden]" ? do
    display none
  ".loading-content" ? do
    width (other "min(100%, 420px)")
    textAlign center
  ".loading-title" ? do
    margin (unitless 0) (unitless 0) (px 14) (unitless 0)
    "font" -: "500 clamp(26px, 4vw, 38px)/1.3 var(--sans)"
    letterSpacing (px (-1))
  ".loading-content p" ? do
    margin (unitless 0) (unitless 0) (unitless 0) (unitless 0)
    color (token "muted")
    "font" -: "12px/1.8 var(--mono)"
  ".loading-progress" ? do
    width (px 140)
    height (px 2)
    margin (px 28) auto (unitless 0) auto
    backgroundColor (token "accent")
    "animation" -: "loading-pulse 1.4s ease-in-out infinite alternate"
  keyframes
    "loading-pulse"
    [ ( 0,
        do
          opacity 0.25
          "transform" -: "scaleX(0.5)"
      ),
      ( 100,
        do
          opacity 1
          "transform" -: "scaleX(1)"
      )
    ]
  query Media.all [Feature "prefers-reduced-motion" (Just "reduce")] $ do
    ".loading-progress" ? do
      "animation" -: "none"
