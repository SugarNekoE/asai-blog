module Styles.Icons exposing (categoryIcon, navIcon, searchIcon, symbol)

import Css exposing (..)
import Styles.Theme as Theme
import Styles.Typography as Typography


navIcon : Style
navIcon =
    batch
        [ Typography.symbols 16 1
        , width (px 18)
        , display inlineFlex
        , alignItems center
        , justifyContent center
        , flexShrink (num 0)
        , height (em 1)
        , property "font-family" "var(--symbols)"
        , fontWeight (int 400)
        , lineHeight (num 1)
        , verticalAlign middle
        ]


categoryIcon : Style
categoryIcon =
    batch
        [ Typography.symbols 16 1
        , Theme.color Theme.CategoryColor
        , width (px 18)
        , textAlign center
        , display inlineFlex
        , alignItems center
        , justifyContent center
        , flexShrink (num 0)
        , height (em 1)
        , property "font-family" "var(--symbols)"
        , fontWeight (int 400)
        , lineHeight (num 1)
        , verticalAlign middle
        ]


symbol : Style
symbol =
    batch
        [ display inlineFlex
        , alignItems center
        , justifyContent center
        , flexShrink (num 0)
        , height (em 1)
        , property "font-family" "var(--symbols)"
        , fontWeight (int 400)
        , lineHeight (num 1)
        , verticalAlign middle
        , width (em 1)
        ]


searchIcon : Style
searchIcon =
    batch
        [ fontSize (px 18)
        ]
