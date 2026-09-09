module Styles.Filters exposing (clearFilters, filterMode, filterbar, indexFilters, searchField, selectedTag, selectedTags, sortButton, tagOption, tagOptions, tagPicker, tagSelectionCount)

import Css exposing (..)
import Css.Global as Global
import Styles.Responsive as Responsive
import Styles.Theme as Theme
import Styles.Typography as Typography


filterbar : Style
filterbar =
    batch
        [ displayFlex
        , flexWrap wrap
        , padding2 (px 12) (px 0)
        , justifyContent spaceBetween
        , alignItems center
        , property "border-bottom" "1px solid var(--border)"
        , property "gap" "12px"
        ]


sortButton : Style
sortButton =
    batch
        [ display inlineFlex
        , alignItems center
        , property "gap" "6px"
        , Typography.monoNormal 10
        , Theme.color Theme.Muted
        , padding2 (px 10) (px 0)
        , property "white-space" "nowrap"
        ]


indexFilters : Style
indexFilters =
    batch
        [ displayFlex
        , alignItems center
        , flexWrap wrap
        , property "gap" "10px"
        , minWidth (px 0)
        , property "flex" "1"
        , property "font" "500 11px var(--mono)"
        ]


tagPicker : Style
tagPicker =
    batch
        [ position relative
        , Global.descendants
            [ Global.selector "summary"
                [ cursor pointer
                , listStyle none
                , property "border" "1px solid var(--border)"
                , borderRadius (px 4)
                , padding2 (px 7) (px 10)
                , Theme.background Theme.Sidebar
                , Theme.color Theme.Text
                , property "font" "inherit"
                ]
            ]
        , Global.descendants
            [ Global.selector "summary::-webkit-details-marker"
                [ display none
                ]
            ]
        , Global.withAttribute "open"
            [ Global.descendants
                [ Global.selector "summary"
                    [ Theme.borderColor Theme.Accent
                    ]
                ]
            ]
        ]


tagSelectionCount : Style
tagSelectionCount =
    batch
        [ marginLeft (px 10)
        , Theme.color Theme.Accent
        ]


tagOptions : Style
tagOptions =
    batch
        [ position absolute
        , property "top" "calc(100% + 8px)"
        , left (px 0)
        , zIndex (int 10)
        , property "width" "min(260px, calc(100vw - 48px))"
        , maxHeight (px 300)
        , overflowY auto
        , padding (px 12)
        , property "border" "1px solid var(--border)"
        , borderRadius (px 5)
        , Theme.background Theme.Sidebar
        , property "box-shadow" "0 8px 24px var(--shadow-popover)"
        ]


filterMode : Style
filterMode =
    batch
        [ margin3 (px 0) (px 0) (px 8)
        , Theme.color Theme.Muted
        , Typography.mono 10 1.6
        ]


tagOption : Style
tagOption =
    batch
        [ Theme.color Theme.TagColor
        , displayFlex
        , alignItems center
        , property "gap" "10px"
        , padding2 (px 8) (px 4)
        , cursor pointer
        , property "overflow-wrap" "anywhere"
        , Global.descendants
            [ Global.selector "input"
                [ property "accent-color" "var(--tag-color)"
                , flexShrink (num 0)
                ]
            ]
        , hover
            [ Theme.background Theme.Hover
            ]
        ]


selectedTags : Style
selectedTags =
    batch
        [ displayFlex
        , flexWrap wrap
        , property "gap" "8px"
        , minWidth (px 0)
        , pseudoClass "empty"
            [ display none
            ]
        ]


selectedTag : Style
selectedTag =
    batch
        [ displayFlex
        , alignItems center
        , property "gap" "10px"
        , padding2 (px 5) (px 8)
        , property "border" "1px solid color-mix(in srgb, var(--tag-color) var(--tag-selected-border-opacity), transparent)"
        , borderRadius (px 4)
        , Theme.color Theme.TagColor
        , property "background" "color-mix(in srgb, var(--tag-color) var(--tag-background-opacity), transparent)"
        , property "font" "inherit"
        , property "overflow-wrap" "anywhere"
        , hover
            [ Theme.background Theme.Hover
            ]
        ]


clearFilters : Style
clearFilters =
    batch
        [ padding2 (px 8) (px 0)
        , Theme.color Theme.Accent
        , property "font" "inherit"
        ]


searchField : Style
searchField =
    batch
        [ displayFlex
        , alignItems center
        , property "gap" "12px"
        , property "border" "1px solid var(--border)"
        , borderRadius (px 5)
        , Theme.background Theme.Sidebar
        , marginTop (px 20)
        , padding2 (px 7) (px 12)
        , Theme.color Theme.Muted
        , pseudoClass "focus-within"
            [ Theme.borderColor Theme.Accent
            ]
        , Global.descendants
            [ Global.selector "input"
                [ width (pct 100)
                , property "border" "0"
                , property "background" "none"
                , Theme.color Theme.Text
                , Typography.mono 11 2
                , outline none
                ]
            ]
        , Global.descendants
            [ Global.selector "input::placeholder"
                [ Theme.color Theme.Faint
                ]
            ]
        , Global.children
            [ Global.selector "span"
                [ fontSize (px 18)
                , lineHeight (num 1)
                ]
            ]
        , Responsive.rules
            [ ( "(max-width: 760px)"
              , [ Global.descendants
                    [ Global.selector "input"
                        [ fontSize (px 10)
                        ]
                    ]
                ]
              )
            ]
        ]
