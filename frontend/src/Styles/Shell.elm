module Styles.Shell exposing (editor, mainContent, pageContent, skipLink, workspace)

import Css exposing (..)
import Css.Global as Global
import Styles.Responsive as Responsive
import Styles.Theme as Theme


workspace : Style
workspace =
    batch
        [ minHeight (vh 100)
        , Global.withClass "is-immersive"
            [ Global.children
                [ Global.selector ".sidebar"
                    [ display none
                    ]
                ]
            ]
        , Global.withClass "is-immersive"
            [ Global.descendants
                [ Global.selector ".topbar"
                    [ display none
                    ]
                ]
            ]
        , Global.withClass "is-immersive"
            [ Global.descendants
                [ Global.selector ".statusbar"
                    [ display none
                    ]
                ]
            ]
        , Global.withClass "is-immersive"
            [ Global.descendants
                [ Global.selector ".prose > .back"
                    [ display none
                    ]
                ]
            ]
        , Global.withClass "is-immersive"
            [ Global.descendants
                [ Global.selector ".editor"
                    [ marginLeft (px 0)
                    ]
                ]
            ]
        , Global.withClass "is-immersive"
            [ Global.descendants
                [ Global.selector ".main-content [id]"
                    [ property "scroll-margin-top" "100px"
                    ]
                ]
            ]
        , Global.withClass "is-immersive"
            [ Global.descendants
                [ Global.selector ".main-content"
                    [ display block
                    , maxWidth (px 1440)
                    , property "padding" "48px clamp(24px, 4vw, 64px)"
                    ]
                ]
            ]
        , Global.withClass "is-immersive"
            [ Global.descendants
                [ Global.selector ".page-content"
                    [ maxWidth none ]
                ]
            ]
        , Global.withClass "is-immersive"
            [ Global.descendants
                [ Global.selector ".prose"
                    [ maxWidth none
                    ]
                ]
            ]
        , Global.withClass "is-immersive"
            [ Global.descendants
                [ Global.selector ".article-header"
                    [ marginTop (px 0)
                    ]
                ]
            ]
        ]


editor : Style
editor =
    batch
        [ marginLeft (px 250)
        , minHeight (vh 100)
        , displayFlex
        , flexDirection column
        , Responsive.rules
            [ ( "(max-width: 1100px)"
              , [ marginLeft (px 220)
                ]
              )
            , ( "(max-width: 760px)"
              , [ marginLeft (px 0)
                ]
              )
            ]
        ]


contentWidth : Float
contentWidth =
    730


gutter : Float
gutter =
    40


mainContent : Style
mainContent =
    batch
        [ focus [ outline none ]
        , width (pct 100)
        , padding3 (px 64) (px gutter) (px 45)
        , margin2 (px 0) auto
        , property "flex" "1"
        , property "display" "grid"
        , property "grid-template-columns" "minmax(0, 1fr) minmax(0, 730px) minmax(0, 1fr)"
        , alignItems start
        , property "gap" "48px"
        , Responsive.rules
            [ ( "(min-width: 1500px)", [ paddingTop (px 80) ] )
            , ( Responsive.outlineNarrow
              , [ property "grid-template-columns" "minmax(0, 1fr)"
                , maxWidth (px (contentWidth + 2 * gutter))
                , property "gap" "32px"
                ]
              )
            , ( "(max-width: 1100px)", [ padding3 (px 50) (px gutter) (px 35) ] )
            , ( "(max-width: 760px)", [ padding3 (px 40) (px 24) (px 25) ] )
            ]
        ]


pageContent : Style
pageContent =
    batch
        [ minWidth (px 0)
        , property "grid-column" "2"
        , width (pct 100)
        , maxWidth (px contentWidth)
        , margin2 (px 0) auto
        , Global.descendants
            [ Global.selector ".prose" [ maxWidth none ] ]
        , Responsive.rules
            [ ( Responsive.outlineNarrow, [ property "grid-column" "1" ] ) ]
        ]


skipLink : Style
skipLink =
    batch
        [ position fixed
        , top (px -60)
        , left (px 20)
        , zIndex (int 20)
        , Theme.background Theme.Accent
        , Theme.color Theme.Sidebar
        , padding2 (px 10) (px 15)
        , focus
            [ top (px 10)
            ]
        ]
