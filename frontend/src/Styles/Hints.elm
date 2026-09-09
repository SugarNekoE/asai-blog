module Styles.Hints exposing (linkHint, linkHintStatus, linkHints)

import Css exposing (..)
import Styles.Theme as Theme
import Styles.Typography as Typography


linkHints : Style
linkHints =
    batch
        [ position fixed
        , property "inset" "0"
        , zIndex (int 20)
        , pointerEvents none
        ]


linkHint : Style
linkHint =
    batch
        [ position fixed
        , padding2 (px 2) (px 5)
        , property "border" "1px solid var(--hint-border)"
        , borderRadius (px 3)
        , Theme.background Theme.HintBackground
        , Theme.color Theme.HintText
        , property "box-shadow" "0 2px 5px var(--shadow-hint)"
        , property "font" "600 12px/1.3 var(--mono)"
        ]


linkHintStatus : Style
linkHintStatus =
    batch
        [ position fixed
        , bottom (px 20)
        , left (pct 50)
        , property "transform" "translateX(-50%)"
        , property "max-width" "calc(100vw - 32px)"
        , padding2 (px 10) (px 16)
        , property "border" "1px solid var(--border)"
        , borderRadius (px 5)
        , Theme.background Theme.Surface
        , Theme.color Theme.Text
        , property "box-shadow" "0 4px 20px var(--shadow-panel)"
        , Typography.mono 12 1.7
        ]
