module Styles.Keymap exposing (keymapDialog, keymapList, keymapRow)

import Css exposing (..)
import Css.Global as Global
import Styles.Theme as Theme


keymapDialog : Style
keymapDialog =
    batch
        [ property "width" "min(560px, calc(100vw - 32px))"
        ]


keymapList : Style
keymapList =
    batch
        [ margin2 (px 20) (px 0)
        ]


keymapRow : Style
keymapRow =
    batch
        [ property "display" "grid"
        , property "grid-template-columns" "minmax(100px, 155px) minmax(0, 1fr)"
        , alignItems center
        , property "gap" "16px"
        , padding2 (px 12) (px 0)
        , property "border-bottom" "1px solid var(--border)"
        , Global.descendants
            [ Global.selector "kbd"
                [ Theme.color Theme.Text
                , fontSize (px 11)
                , lineHeight (num 1.8)
                ]
            ]
        , Global.descendants
            [ Global.selector "dd"
                [ margin (px 0)
                , Theme.color Theme.Muted
                , fontSize (px 12)
                ]
            ]
        ]
