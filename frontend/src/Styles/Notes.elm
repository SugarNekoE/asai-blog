module Styles.Notes exposing (postArrow, postCategory, postDate, postDetails, postKicker, postRow, readTime, tag, tags)

import Css exposing (..)
import Css.Global as Global
import Styles.Responsive as Responsive
import Styles.Theme as Theme
import Styles.Typography as Typography


postRow : Style
postRow =
    batch
        [ property "display" "grid"
        , property "grid-template-columns" "75px 1fr"
        , property "gap" "22px"
        , property "border-bottom" "1px solid var(--border)"
        , padding3 (px 28) (px 0) (px 27)
        , Global.descendants
            [ Global.selector "h3"
                [ fontSize (px 20)
                , lineHeight (num 1.45)
                , letterSpacing (px -0.45)
                , fontWeight (int 550)
                , marginBottom (px 8)
                ]
            ]
        , Global.descendants
            [ Global.selector "h3 a"
                [ displayFlex
                , alignItems center
                , justifyContent spaceBetween
                , property "gap" "15px"
                ]
            ]
        , hover
            [ Global.descendants
                [ Global.selector "h3 a"
                    [ Theme.color Theme.Accent
                    ]
                ]
            ]
        , Global.descendants
            [ Global.selector "h3 a[data-tab-focus]:focus"
                [ Theme.color Theme.Accent
                ]
            ]
        , hover
            [ Global.descendants
                [ Global.selector ".post-arrow"
                    [ Theme.color Theme.Accent
                    ]
                ]
            ]
        , Responsive.rules
            [ ( "(max-width: 760px)"
              , [ property "grid-template-columns" "48px 1fr"
                , property "gap" "16px"
                , padding2 (px 25) (px 0)
                ]
              )
            , ( "(max-width: 760px)"
              , [ Global.descendants
                    [ Global.selector "h3"
                        [ fontSize (px 18)
                        ]
                    ]
                ]
              )
            ]
        ]


postDate : Style
postDate =
    batch
        [ Typography.mono 13 1.6
        , Theme.color Theme.Muted
        , paddingTop (px 4)
        , Global.descendants
            [ Global.selector "small"
                [ display block
                , fontSize (px 10)
                , Theme.color Theme.Faint
                , marginTop (px 2)
                ]
            ]
        , Responsive.rules
            [ ( "(max-width: 760px)"
              , [ fontSize (px 11)
                ]
              )
            ]
        ]


postKicker : Style
postKicker =
    batch
        [ flexWrap wrap
        , property "row-gap" "6px"
        , Typography.monoNormal 9
        , letterSpacing (px 1)
        , Theme.color Theme.Faint
        , displayFlex
        , property "gap" "16px"
        , marginBottom (px 10)
        ]


readTime : Style
readTime =
    batch
        [ letterSpacing (px 0)
        ]


postArrow : Style
postArrow =
    batch
        [ Typography.symbols 18 1
        , Theme.color Theme.Faint
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


postDetails : Style
postDetails =
    batch
        [ Global.children
            [ Global.selector "p"
                [ fontSize (px 12)
                , Theme.color Theme.Muted
                , lineHeight (num 1.9)
                , marginBottom (px 15)
                , maxWidth (px 600)
                ]
            ]
        , Responsive.rules
            [ ( "(max-width: 760px)"
              , [ Global.children
                    [ Global.selector "p"
                        [ fontSize (px 12)
                        ]
                    ]
                ]
              )
            ]
        ]


tags : Style
tags =
    batch
        [ displayFlex
        , property "gap" "10px"
        , flexWrap wrap
        ]


tag : Style
tag =
    batch
        [ Global.withAttribute "aria-pressed='true'"
            [ property "border-color" "currentColor"
            ]
        , hover
            [ Theme.background Theme.Hover
            ]
        , Typography.mono 9 1.6
        , Theme.color Theme.TagColor
        , property "background" "color-mix(in srgb, var(--tag-color) var(--tag-background-opacity), transparent)"
        , property "border" "1px solid color-mix(in srgb, var(--tag-color) var(--tag-border-opacity), transparent)"
        , borderRadius (px 3)
        , padding2 (px 2) (px 7)
        ]


postCategory : Style
postCategory =
    batch
        [ Theme.color Theme.CategoryColor
        ]
