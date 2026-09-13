module Styles.Intro exposing (collectionHeader, emptyState, intro, introQuote, noteCount, notebookEnd, quoteAttribution, resetButton, resultCount)

import Css exposing (..)
import Css.Global as Global
import Styles.Responsive as Responsive
import Styles.Theme as Theme
import Styles.Typography as Typography


intro : Style
intro =
    batch
        [ Global.descendants
            [ Global.selector "h1"
                [ property "font-size" "clamp(32px, 3.25vw, 48px)"
                , lineHeight (num 1.28)
                , letterSpacing (px -1.8)
                , fontWeight (int 550)
                , marginBottom (px 23)
                ]
            ]
        , Global.descendants
            [ Global.selector "h1 em"
                [ fontStyle normal
                , Theme.color Theme.Accent
                ]
            ]
        , Responsive.rules
            [ ( "(min-width: 1500px)"
              , [ Global.descendants
                    [ Global.selector "h1"
                        [ fontSize (px 50)
                        ]
                    ]
                ]
              )
            , ( "(max-width: 760px)"
              , [ Global.descendants
                    [ Global.selector "h1"
                        [ fontSize (px 36)
                        , letterSpacing (px -1.4)
                        ]
                    ]
                ]
              )
            ]
        ]


introQuote : Style
introQuote =
    batch
        [ Theme.color Theme.Muted
        , displayFlex
        , flexWrap wrap
        , alignItems baseline
        , property "gap" "4px 12px"
        , margin (px 0)
        , fontSize (px 14)
        , lineHeight (num 1.9)
        , Responsive.rules
            [ ( "(max-width: 760px)"
              , [ fontSize (px 13)
                ]
              )
            ]
        ]


quoteAttribution : Style
quoteAttribution =
    batch
        [ Typography.monoNormal 11
        , whiteSpace noWrap
        , Global.descendants
            [ Global.selector "cite" [ fontStyle normal ] ]
        ]


noteCount : Style
noteCount =
    batch
        [ Typography.monoNormal 10
        , Theme.color Theme.Faint
        , letterSpacing (px 0)
        , whiteSpace noWrap
        ]


collectionHeader : Style
collectionHeader =
    batch
        [ displayFlex
        , flexWrap wrap
        , property "gap" "12px"
        , justifyContent spaceBetween
        , alignItems baseline
        , marginTop (px 60)
        , marginBottom (px 6)
        , Global.descendants
            [ Global.selector "h2"
                [ fontSize (px 17)
                , fontWeight (int 550)
                , letterSpacing (px -0.3)
                , margin (px 0)
                ]
            ]
        , Responsive.rules
            [ ( "(max-width: 760px)"
              , [ marginTop (px 48)
                ]
              )
            ]
        ]


resultCount : Style
resultCount =
    batch
        [ Typography.monoNormal 9
        , Theme.color Theme.Faint
        , margin3 (px 13) (px 0) (px 3)
        ]


notebookEnd : Style
notebookEnd =
    batch
        [ padding3 (px 35) (px 0) (px 10)
        , displayFlex
        , property "gap" "13px"
        , alignItems center
        , justifyContent center
        , Typography.monoNormal 10
        , Theme.color Theme.Faint
        , Responsive.rules
            [ ( "(max-width: 760px)"
              , [ fontSize (px 9)
                ]
              )
            ]
        ]


emptyState : Style
emptyState =
    batch
        [ textAlign center
        , padding2 (px 55) (px 10)
        , Global.children
            [ Global.selector "span"
                [ fontSize (px 35)
                ]
            ]
        , Global.descendants
            [ Global.selector "h3"
                [ fontSize (px 18)
                , margin3 (px 15) (px 0) (px 5)
                ]
            ]
        , Global.descendants
            [ Global.selector "p"
                [ fontSize (px 13)
                , Theme.color Theme.Muted
                ]
            ]
        ]


resetButton : Style
resetButton =
    batch
        [ Theme.color Theme.Accent
        , Typography.monoNormal 12
        , padding (px 12)
        ]
