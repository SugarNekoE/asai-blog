module Styles.Header exposing (breadcrumbs, currentCategory, iconButton, localClock, mobileToggle, slash, topActions, topbar)

import Css exposing (..)
import Css.Global as Global
import Styles.Responsive as Responsive
import Styles.Theme as Theme
import Styles.Typography as Typography


topbar : Style
topbar =
    batch
        [ height (px 65)
        , flexShrink (num 0)
        , padding2 (px 0) (px 35)
        , displayFlex
        , alignItems center
        , justifyContent spaceBetween
        , property "border-bottom" "1px solid var(--border)"
        , Typography.monoNormal 11
        , Responsive.rules
            [ ( "(max-width: 1100px)"
              , [ padding2 (px 0) (px 25)
                ]
              )
            , ( "(max-width: 760px)"
              , [ height (px Responsive.mobileTopbarHeight)
                , padding2 (px 0) (px 15)
                , justifyContent flexStart
                , position sticky
                , top (px 0)
                , zIndex (int 6)
                , Theme.background Theme.Bg
                ]
              )
            ]
        ]


breadcrumbs : Style
breadcrumbs =
    batch
        [ displayFlex
        , alignItems center
        , property "gap" "15px"
        , minWidth (px 0)
        , Global.children
            [ Global.selector "a:first-child"
                [ flexShrink (num 0)
                ]
            ]
        , Responsive.rules
            [ ( "(max-width: 760px)"
              , [ property "gap" "10px"
                , property "flex" "1"
                ]
              )
            ]
        ]


currentCategory : Style
currentCategory =
    batch
        [ minWidth (px 0)
        , overflow hidden
        , textOverflow ellipsis
        , property "white-space" "nowrap"
        ]


slash : Style
slash =
    batch
        [ Theme.color Theme.Faint
        ]


topActions : Style
topActions =
    batch
        [ displayFlex
        , alignItems center
        , property "gap" "20px"
        , Responsive.rules
            [ ( "(max-width: 760px)"
              , [ marginLeft auto
                , property "gap" "8px"
                , flexShrink (num 0)
                ]
              )
            ]
        ]


localClock : Style
localClock =
    batch
        [ display inlineFlex
        , alignItems center
        , minHeight (px 36)
        , lineHeight (num 1)
        , property "white-space" "nowrap"
        , Theme.color Theme.Faint
        , fontSize (px 10)
        , Responsive.rules
            [ ( "(max-width: 1100px)"
              , [ fontSize (px 9)
                ]
              )
            , ( "(max-width: 760px)"
              , [ display inlineFlex
                ]
              )
            ]
        ]


iconButton : Style
iconButton =
    batch
        [ display inlineFlex
        , alignItems center
        , justifyContent center
        , padding (px 0)
        , property "font" "400 20px/1 var(--symbols)"
        , minWidth (px 36)
        , minHeight (px 36)
        , Theme.color Theme.Muted
        ]


mobileToggle : Style
mobileToggle =
    batch
        [ display none
        , Responsive.rules
            [ ( "(max-width: 760px)"
              , [ display block
                , fontSize (px 18)
                , marginRight (px 10)
                ]
              )
            ]
        ]
