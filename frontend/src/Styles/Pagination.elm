module Styles.Pagination exposing (pagination, paginationControls, paginationGap, paginationPages, paginationSettings, paginationStep, paginationSummary)

import Css exposing (..)
import Css.Global as Global
import Styles.Theme as Theme
import Styles.Typography as Typography


pagination : Style
pagination =
    batch
        [ displayFlex
        , flexWrap wrap
        , alignItems center
        , justifyContent spaceBetween
        , property "gap" "16px"
        , padding2 (px 24) (px 0)
        , Theme.color Theme.Muted
        , Typography.mono 11 1.6
        ]


paginationSettings : Style
paginationSettings =
    batch
        [ displayFlex
        , flexWrap wrap
        , alignItems center
        , property "gap" "6px"
        , Global.descendants
            [ Global.selector "select"
                [ padding2 (px 6) (px 9)
                , property "border" "1px solid var(--border)"
                , borderRadius (px 4)
                , Theme.background Theme.Sidebar
                , Theme.color Theme.Text
                , property "font" "inherit"
                ]
            ]
        ]


paginationControls : Style
paginationControls =
    batch
        [ displayFlex
        , flexWrap wrap
        , alignItems center
        , property "gap" "6px"
        , Global.descendants
            [ Global.selector "button"
                [ padding2 (px 6) (px 9)
                , property "border" "1px solid var(--border)"
                , borderRadius (px 4)
                , Theme.background Theme.Sidebar
                , Theme.color Theme.Text
                , property "font" "inherit"
                ]
            ]
        , Global.descendants
            [ Global.selector "button[aria-current='page']"
                [ Theme.borderColor Theme.Accent
                , Theme.color Theme.Accent
                ]
            ]
        , Global.descendants
            [ Global.selector "button:disabled"
                [ Theme.color Theme.Faint
                , opacity (num 0.55)
                ]
            ]
        ]


paginationPages : Style
paginationPages =
    batch
        [ displayFlex
        , flexWrap wrap
        , alignItems center
        , property "gap" "6px"
        ]


paginationStep : Style
paginationStep =
    batch
        [ displayFlex
        , flexWrap wrap
        , alignItems center
        , property "gap" "6px"
        ]


paginationGap : Style
paginationGap =
    batch
        [ padding2 (px 0) (px 3)
        ]


paginationSummary : Style
paginationSummary =
    batch
        [ property "white-space" "nowrap"
        ]
