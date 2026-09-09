module Styles.Dialog exposing (launcherClose, launcherCount, launcherEmpty, launcherFooter, launcherHeading, launcherHelp, launcherPanel, launcherResult, launcherResultDescription, launcherResultMeta, launcherResultTitle, launcherResults, launcherSearch, launcherTag, searchDialog)

import Css exposing (..)
import Css.Global as Global
import Styles.Theme as Theme
import Styles.Typography as Typography


searchDialog : Style
searchDialog =
    batch
        [ position fixed
        , property "inset" "0 0 auto"
        , property "width" "min(680px, calc(100vw - 32px))"
        , maxWidth none
        , property "max-height" "calc(100dvh - min(12vh, 96px) - 24px)"
        , property "margin" "min(12vh, 96px) auto 0"
        , padding (px 0)
        , property "border" "1px solid var(--border)"
        , borderRadius (px 10)
        , Theme.background Theme.Bg
        , Theme.color Theme.Text
        , property "box-shadow" "0 24px 80px var(--shadow-dialog)"
        , focus [ outline none ]
        , pseudoElement "backdrop"
            [ Theme.background Theme.Backdrop
            , property "backdrop-filter" "blur(3px)"
            ]
        ]


launcherPanel : Style
launcherPanel =
    batch
        [ padding (px 22)
        , focus [ outline none ]
        ]


launcherHeading : Style
launcherHeading =
    batch
        [ displayFlex
        , alignItems center
        , justifyContent spaceBetween
        , property "gap" "16px"
        , marginBottom (px 18)
        , Global.descendants
            [ Global.selector "h2"
                [ margin (px 0)
                , fontSize (px 18)
                , fontWeight (int 600)
                ]
            ]
        ]


launcherClose : Style
launcherClose =
    batch
        [ padding2 (px 5) (px 10)
        , property "border" "1px solid var(--border)"
        , borderRadius (px 4)
        , Theme.color Theme.Muted
        , Typography.monoNormal 11
        ]


launcherSearch : Style
launcherSearch =
    batch
        [ width (pct 100)
        , padding (px 13)
        , property "border" "1px solid var(--border)"
        , borderRadius (px 5)
        , Theme.background Theme.Sidebar
        , Theme.color Theme.Text
        , Typography.mono 14 1.6
        , focus
            [ Theme.borderColor Theme.Accent
            , outline none
            ]
        ]


launcherHelp : Style
launcherHelp =
    batch
        [ Theme.color Theme.Muted
        , Typography.mono 11 1.8
        , margin2 (px 12) (px 0)
        ]


launcherCount : Style
launcherCount =
    batch
        [ Theme.color Theme.Muted
        , Typography.mono 11 1.8
        , margin3 (px 0) (px 0) (px 8)
        ]


launcherFooter : Style
launcherFooter =
    batch
        [ Theme.color Theme.Muted
        , Typography.mono 11 1.8
        , paddingTop (px 14)
        , marginTop (px 12)
        , property "border-top" "1px solid var(--border)"
        ]


launcherResults : Style
launcherResults =
    batch
        [ property "max-height" "min(46vh, 400px)"
        , overflowY auto
        , property "overscroll-behavior" "contain"
        , focus [ outline none ]
        ]


launcherResult : Style
launcherResult =
    batch
        [ displayFlex
        , flexDirection column
        , property "gap" "6px"
        , padding (px 14)
        , property "border" "1px solid transparent"
        , borderRadius (px 5)
        , property "overflow-wrap" "anywhere"
        , Global.withClass "is-selected"
            [ Theme.borderColor Theme.Border
            , Theme.background Theme.Surface
            ]
        , Global.withClass "is-selected"
            [ Global.descendants
                [ Global.selector ".launcher-result-title"
                    [ Theme.color Theme.Accent
                    ]
                ]
            ]
        ]


launcherResultTitle : Style
launcherResultTitle =
    batch
        [ Theme.color Theme.Text
        , fontSize (px 15)
        , fontWeight (int 600)
        ]


launcherResultDescription : Style
launcherResultDescription =
    batch
        [ property "display" "-webkit-box"
        , property "-webkit-box-orient" "vertical"
        , property "-webkit-line-clamp" "2"
        , property "line-clamp" "2"
        , overflow hidden
        , Theme.color Theme.Muted
        , fontSize (px 12)
        , lineHeight (num 1.7)
        ]


launcherResultMeta : Style
launcherResultMeta =
    batch
        [ Theme.color Theme.CategoryColor
        , Typography.mono 10 1.8
        ]


launcherTag : Style
launcherTag =
    batch
        [ Theme.color Theme.TagColor
        ]


launcherEmpty : Style
launcherEmpty =
    batch
        [ padding2 (px 28) (px 8)
        , Theme.color Theme.Muted
        , fontSize (px 13)
        , textAlign center
        ]
