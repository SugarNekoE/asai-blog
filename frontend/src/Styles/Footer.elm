module Styles.Footer exposing (statusDivider, statusbar)

import Css exposing (..)
import Css.Global as Global
import Styles.Responsive as Responsive
import Styles.Theme as Theme
import Styles.Typography as Typography


statusbar : Style
statusbar =
    batch
        [ displayFlex
        , flexWrap wrap
        , justifyContent spaceBetween
        , property "gap" "10px"
        , padding2 (px 9) (px 22)
        , property "border-top" "1px solid var(--border)"
        , Theme.color Theme.Faint
        , Theme.background Theme.Sidebar
        , Typography.monoNormal 9
        , Responsive.rules
            [ ( "(max-width: 760px)"
              , [ padding2 (px 10) (px 15)
                , fontSize (px 8)
                ]
              )
            , ( "(max-width: 760px)"
              , [ Global.descendants
                    [ Global.selector ".status-divider"
                        [ margin2 (px 0) (px 6)
                        ]
                    ]
                ]
              )
            ]
        ]


statusDivider : Style
statusDivider =
    batch
        [ margin2 (px 0) (px 12)
        ]
