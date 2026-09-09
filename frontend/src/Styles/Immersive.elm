module Styles.Immersive exposing (immersiveBrand, immersiveControls, immersiveExit, immersiveHeader)

import Css exposing (..)
import Css.Global as Global
import Styles.Theme as Theme
import Styles.Typography as Typography


immersiveHeader : Style
immersiveHeader =
    batch
        [ position sticky
        , top (px 0)
        , zIndex (int 4)
        , displayFlex
        , flexWrap wrap
        , alignItems center
        , justifyContent spaceBetween
        , property "gap" "12px 24px"
        , width (pct 100)
        , maxWidth (px 1440)
        , margin2 (px 0) auto
        , property "padding" "20px clamp(24px, 4vw, 64px)"
        , Theme.background Theme.Bg
        ]


immersiveBrand : Style
immersiveBrand =
    batch
        [ display inlineFlex
        , alignItems center
        , property "gap" "10px"
        , fontSize (px 17)
        , fontWeight (int 650)
        , letterSpacing (px -0.5)
        , Global.descendants
            [ Global.selector ".brand-mark"
                [ fontSize (px 28)
                ]
            ]
        ]


immersiveControls : Style
immersiveControls =
    batch
        [ displayFlex
        , flexWrap wrap
        , alignItems center
        , property "gap" "12px 20px"
        , Theme.color Theme.Muted
        , Typography.mono 11 1.6
        ]


immersiveExit : Style
immersiveExit =
    batch
        [ display inlineFlex
        , alignItems center
        , property "gap" "8px"
        , padding2 (px 4) (px 0)
        , color inherit
        , property "font" "inherit"
        , Global.descendants
            [ Global.selector "kbd"
                [ Theme.color Theme.Text
                ]
            ]
        , hover
            [ Theme.color Theme.Accent
            ]
        ]
