module Styles.Sidebar exposing (categoryItem, categoryLabel, categoryName, count, keymapTrigger, navItem, searchLaunch, sidebar, sidebarBottom, sidebarLabel)

import Css exposing (..)
import Css.Global as Global
import Styles.Responsive as Responsive
import Styles.Theme as Theme
import Styles.Typography as Typography


sidebar : Style
sidebar =
    batch
        [ position fixed
        , property "inset" "0 auto 0 0"
        , width (px 250)
        , Theme.background Theme.Sidebar
        , property "border-right" "1px solid var(--border)"
        , padding3 (px 35) (px 20) (px 25)
        , displayFlex
        , flexDirection column
        , overflow auto
        , zIndex (int 5)
        , Responsive.rules
            [ ( "(max-width: 1100px)"
              , [ width (px 220)
                , paddingLeft (px 15)
                , paddingRight (px 15)
                ]
              )
            , ( "(max-width: 760px)"
              , [ display none
                , top (px 60)
                , width (px 260)
                , property "box-shadow" "20px 0 40px var(--shadow-panel)"
                ]
              )
            , ( "(max-width: 760px)"
              , [ Global.withClass "is-open"
                    [ displayFlex
                    ]
                ]
              )
            , ( "(max-width: 760px)"
              , [ Global.descendants
                    [ Global.selector ".brand"
                        [ display none
                        ]
                    ]
                ]
              )
            ]
        ]


searchLaunch : Style
searchLaunch =
    batch
        [ displayFlex
        , alignItems center
        , property "gap" "10px"
        , textAlign left
        , Theme.background Theme.Surface
        , property "border" "1px solid var(--border)"
        , borderRadius (px 5)
        , padding2 (px 9) (px 10)
        , Typography.monoNormal 11
        , Theme.color Theme.Muted
        , marginBottom (px 34)
        , minHeight (px 38)
        , Global.descendants
            [ Global.selector "kbd"
                [ marginLeft auto
                ]
            ]
        ]


sidebarLabel : Style
sidebarLabel =
    batch
        [ Typography.monoNormal 10
        , letterSpacing (px 1.5)
        , Theme.color Theme.Faint
        , displayFlex
        , justifyContent spaceBetween
        , padding2 (px 0) (px 10)
        , marginBottom (px 14)
        ]


navItem : Style
navItem =
    batch
        [ displayFlex
        , alignItems center
        , property "gap" "10px"
        , padding2 (px 9) (px 11)
        , borderRadius (px 4)
        , fontSize (px 12)
        , Theme.color Theme.Muted
        , width (pct 100)
        , textAlign left
        , hover
            [ Theme.background Theme.Hover
            ]
        , Global.withClass "selected"
            [ Theme.background Theme.ActiveBackground
            , Theme.color Theme.Accent
            , property "box-shadow" "inset 2px 0 var(--accent)"
            ]
        ]


categoryItem : Style
categoryItem =
    batch
        [ displayFlex
        , alignItems center
        , property "gap" "10px"
        , padding2 (px 9) (px 11)
        , borderRadius (px 4)
        , fontSize (px 12)
        , Theme.color Theme.Muted
        , width (pct 100)
        , textAlign left
        , hover
            [ Theme.background Theme.Hover
            ]
        , property "font" "500 12px/1.7 var(--mono)"
        , Global.withClass "active"
            [ Theme.background Theme.Surface
            , Theme.color Theme.Accent
            ]
        ]


count : Style
count =
    batch
        [ marginLeft auto
        , Theme.color Theme.Faint
        , Typography.monoNormal 10
        ]


categoryLabel : Style
categoryLabel =
    batch
        [ marginTop (px 36)
        ]


categoryName : Style
categoryName =
    batch
        [ minWidth (px 0)
        , overflow hidden
        , textOverflow ellipsis
        , property "white-space" "nowrap"
        ]


sidebarBottom : Style
sidebarBottom =
    batch
        [ displayFlex
        , alignItems center
        , justifyContent spaceBetween
        , property "gap" "12px"
        , marginTop auto
        , padding3 (px 45) (px 10) (px 0)
        , Typography.mono 10 1.9
        , Theme.color Theme.Faint
        , Global.descendants
            [ Global.selector "p"
                [ margin3 (px 8) (px 0) (px 0)
                ]
            ]
        ]


keymapTrigger : Style
keymapTrigger =
    batch
        [ flexShrink (num 0)
        , minWidth (px 24)
        , minHeight (px 24)
        , property "border" "1px solid var(--border)"
        , borderRadius (px 4)
        , Typography.monoNormal 11
        ]
