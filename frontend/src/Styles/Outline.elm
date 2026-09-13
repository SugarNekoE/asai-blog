module Styles.Outline exposing (links, pageOutline)

import Css exposing (..)
import Css.Global as Global
import Styles.Responsive as Responsive
import Styles.Theme as Theme
import Styles.Typography as Typography


pageOutline : Style
pageOutline =
    batch
        [ position sticky
        , property "grid-column" "3"
        , property "justify-self" "end"
        , width (pct 100)
        , maxWidth (px 200)
        , top (px 32)
        , alignSelf start
        , displayFlex
        , flexDirection column
        , property "max-height" "calc(100vh - 64px)"
        , overflow hidden
        , padding4 (px 4) (px 0) (px 4) (px 20)
        , property "border-left" "1px solid var(--border)"
        , property "background" "transparent"
        , Global.descendants
            [ Global.selector "h2"
                [ margin3 (px 0) (px 0) (px 14)
                , flexShrink (num 0)
                , Theme.color Theme.Muted
                , property "font" "600 11px/1.6 var(--mono)"
                , letterSpacing (px 1.4)
                ]
            ]
        , Global.descendants
            [ Global.selector "nav a"
                [ display block
                , Theme.color Theme.Muted
                , Typography.mono 12 1.7
                , padding2 (px 7) (px 0)
                , property "overflow-wrap" "anywhere"
                ]
            ]
        , Global.descendants
            [ Global.selector "nav a:hover"
                [ Theme.color Theme.Accent
                ]
            ]
        , Global.descendants
            [ Global.selector "nav a[aria-current='location']"
                [ Theme.color Theme.Accent
                ]
            ]
        , Responsive.rules
            [ ( Responsive.outlineNarrow
              , [ position static
                , property "grid-column" "1"
                , property "justify-self" "stretch"
                , order (int -1)
                , width (pct 100)
                , maxWidth (px 730)
                , property "max-height" "min(28vh, 200px)"
                , margin2 (px 0) auto
                ]
              )
            ]
        ]


links : Style
links =
    batch
        [ minHeight (px 0)
        , overflowY auto
        , property "overscroll-behavior" "contain"
        , property "scrollbar-gutter" "stable"
        ]
