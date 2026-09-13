module Layout exposing (Actions, PageTimings, State, view)

import BrowserClock exposing (Clock)
import Html.Styled as Html exposing (..)
import Html.Styled.Attributes exposing (..)
import Html.Styled.Events exposing (onClick)
import Post exposing (Heading, Post)
import Set
import Styles.Footer as FooterStyles
import Styles.Header as HeaderStyles
import Styles.Icons as IconsStyles
import Styles.Immersive as ImmersiveStyles
import Styles.Outline as OutlineStyles
import Styles.Shell as ShellStyles
import Styles.Sidebar as SidebarStyles
import ThemePreference
import Url


type alias PageTimings =
    { loading : Float
    , rendering : Float
    }


type alias State a =
    { a
        | posts : List Post
        , category : String
        , page : String
        , menu : Bool
        , clock : Clock
        , theme : ThemePreference.Preference
        , immersive : Bool
        , headings : List Heading
        , outlineVisible : Bool
        , activeHeading : Maybe String
        , timings : Maybe PageTimings
    }


type alias Actions msg =
    { toggleMenu : msg
    , toggleTheme : msg
    , openSearch : msg
    , openKeymap : msg
    , navigateCategory : String -> msg
    , toggleImmersive : msg
    }


view : Actions msg -> State a -> Html msg -> List (Html msg) -> Html msg
view actions model content panels =
    div [ css [ ShellStyles.workspace ], classList [ ( "workspace", True ), ( "is-immersive", model.immersive ) ] ]
        ([ a [ class "skip-link", css [ ShellStyles.skipLink ], href "#main" ] [ text "Skip to content" ]
         , sidebar actions model
         , div [ class "editor", css [ ShellStyles.editor ] ]
            [ header [ class "topbar", css [ HeaderStyles.topbar ] ]
                [ button
                    [ class "icon-button mobile-toggle"
                    , id "mobile-menu-toggle"
                    , css [ HeaderStyles.iconButton, HeaderStyles.mobileToggle ]
                    , onClick actions.toggleMenu
                    , attribute "aria-label" "Toggle navigation"
                    , attribute "aria-controls" "navigation"
                    , attribute "aria-expanded"
                        (if model.menu then
                            "true"

                         else
                            "false"
                        )
                    ]
                    [ text "☰" ]
                , nav [ class "breadcrumbs", css [ HeaderStyles.breadcrumbs ], attribute "aria-label" "Breadcrumb" ]
                    [ a [ class "muted", href "/" ] [ text "Asai Blog" ]
                    , span [ class "slash", css [ HeaderStyles.slash ], attribute "aria-hidden" "true" ] [ text "/" ]
                    , if model.page == "post" && not (String.isEmpty model.category) then
                        a
                            [ class "current-category"
                            , css [ HeaderStyles.currentCategory ]
                            , href ("/?category=" ++ Url.percentEncode model.category)
                            , title model.category
                            ]
                            [ text model.category ]

                      else
                        span [ class "current-category", css [ HeaderStyles.currentCategory ] ]
                            [ text
                                (if model.page == "404" then
                                    "Page not found"

                                 else if String.isEmpty model.category then
                                    "All Notes"

                                 else
                                    model.category
                                )
                            ]
                    ]
                , div [ class "top-actions", css [ HeaderStyles.topActions ] ]
                    [ time
                        [ class "local-clock"
                        , css [ HeaderStyles.localClock ]
                        , datetime model.clock.iso
                        , attribute "aria-label" "Current local time"
                        , title "Your browser's local time"
                        ]
                        [ text model.clock.label ]
                    , button
                        [ class "icon-button"
                        , css [ HeaderStyles.iconButton ]
                        , onClick actions.toggleTheme
                        , attribute "aria-label" "Toggle color theme"
                        , attribute "aria-description" (ThemePreference.description model.theme)
                        , title (ThemePreference.description model.theme)
                        , attribute "data-theme-preference" (ThemePreference.toString model.theme)
                        ]
                        [ text (ThemePreference.icon model.theme) ]
                    ]
                ]
            , if model.immersive then
                immersiveHeader actions

              else
                text ""
            , main_
                [ id "main"
                , tabindex -1
                , css [ ShellStyles.mainContent ]
                , classList
                    [ ( "main-content", True )
                    , ( "reading-layout", model.page == "post" && not model.immersive && model.outlineVisible && not (List.isEmpty model.headings) )
                    ]
                ]
                [ div [ class "page-content", css [ ShellStyles.pageContent ] ] [ content ]
                , if model.page == "post" && not model.immersive && model.outlineVisible && not (List.isEmpty model.headings) then
                    pageOutline model.activeHeading model.headings

                  else
                    text ""
                ]
            , footer
                [ class "statusbar"
                , css [ FooterStyles.statusbar ]
                ]
                [ span
                    [ class "page-timings"
                    , attribute "aria-label" "Page performance"
                    , title "Loading: navigation start to load event. Rendering: Elm initialization to first paint opportunity."
                    ]
                    [ text
                        (case model.timings of
                            Just timings ->
                                "loading "
                                    ++ formatMilliseconds timings.loading
                                    ++ "ms / rendered "
                                    ++ formatMilliseconds timings.rendering
                                    ++ "ms"

                            Nothing ->
                                "loading… / rendering…"
                        )
                    ]
                , a
                    [ href "https://forge.asnk.io/sugar/asai-blog"
                    , title "Asai Blog source repository"
                    ]
                    [ text "Markdown"
                    , span
                        [ class "status-divider"
                        , css [ FooterStyles.statusDivider ]
                        ]
                        [ text "·"
                        ]
                    , text "Hakyll + Elm"
                    , span
                        [ class "status-divider"
                        , css [ FooterStyles.statusDivider ]
                        ]
                        [ text "·"
                        ]
                    , text "UTF-8"
                    ]
                ]
            ]
         ]
            ++ panels
        )


immersiveHeader : Actions msg -> Html msg
immersiveHeader actions =
    header [ class "immersive-header", css [ ImmersiveStyles.immersiveHeader ] ]
        [ a [ class "immersive-brand", css [ ImmersiveStyles.immersiveBrand ], href "/" ]
            [ span [ class "brand-mark", attribute "aria-hidden" "true" ] [ text "λ" ]
            , span [] [ text "Asai Blog" ]
            ]
        , div [ class "immersive-controls", css [ ImmersiveStyles.immersiveControls ] ]
            [ span [ class "immersive-label" ] [ text "Immersive Mode" ]
            , button
                [ class "immersive-exit"
                , css [ ImmersiveStyles.immersiveExit ]
                , onClick actions.toggleImmersive
                , attribute "aria-label" "Exit immersive mode"
                , title "Exit immersive mode (Shift+I)"
                ]
                [ kbd [] [ text "Shift + I" ]
                , span [] [ text "to exit" ]
                ]
            ]
        ]


formatMilliseconds : Float -> String
formatMilliseconds milliseconds =
    milliseconds
        |> Basics.max 0
        |> round
        |> String.fromInt


sidebar : Actions msg -> State a -> Html msg
sidebar actions model =
    let
        categories =
            model.posts |> List.map .category |> Set.fromList |> Set.toList
    in
    aside [ css [ SidebarStyles.sidebar ], classList [ ( "sidebar", True ), ( "is-open", model.menu ) ], id "navigation" ]
        [ a
            [ class "brand"
            , href "/"
            ]
            [ span
                [ class "brand-mark"
                ]
                [ text "λ"
                ]
            , span
                []
                [ text "Asai Blog"
                ]
            ]
        , button
            [ class "search-launch"
            , css [ SidebarStyles.searchLaunch ]
            , onClick actions.openSearch
            , attribute "aria-haspopup" "dialog"
            , attribute "aria-controls" "search-dialog"
            ]
            [ span [ class "symbol search-icon", css [ IconsStyles.symbol, IconsStyles.searchIcon ], attribute "aria-hidden" "true" ] [ text "⌕" ]
            , span [] [ text "Search notes" ]
            , kbd [] [ text "/" ]
            ]
        , div [ class "sidebar-label", css [ SidebarStyles.sidebarLabel ] ] [ text "EXPLORER" ]
        , nav [ attribute "aria-label" "Main navigation" ]
            [ a
                [ href "/"
                , css [ SidebarStyles.navItem ]
                , classList
                    [ ( "nav-item"
                      , True
                      )
                    , ( "selected"
                      , model.page == "index" && String.isEmpty model.category
                      )
                    ]
                ]
                [ span
                    [ class "nav-icon"
                    , css [ IconsStyles.navIcon ]
                    ]
                    [ text "▤"
                    ]
                , text "All Notes"
                , span
                    [ class "count"
                    , css [ SidebarStyles.count ]
                    ]
                    [ text (String.fromInt (List.length model.posts))
                    ]
                ]
            , a
                [ href "/feed.xml"
                , class "nav-item"
                , css [ SidebarStyles.navItem ]
                ]
                [ span
                    [ class "nav-icon"
                    , css [ IconsStyles.navIcon ]
                    ]
                    [ text "◉"
                    ]
                , text "RSS feed"
                , span
                    [ class "count symbol"
                    , css [ SidebarStyles.count, IconsStyles.symbol ]
                    ]
                    [ text "↗"
                    ]
                ]
            ]
        , div [ class "sidebar-label category-label", css [ SidebarStyles.sidebarLabel, SidebarStyles.categoryLabel ] ] [ text "CATEGORIES" ]
        , nav [ class "category-list", attribute "aria-label" "Categories" ]
            (List.map (categoryView actions model) categories)
        , div
            [ class "sidebar-bottom"
            , css [ SidebarStyles.sidebarBottom ]
            ]
            [ div [ class "sidebar-links" ]
                [ a [ href "https://sne.moe" ] [ text "sne.moe ↗" ]
                , p []
                    [ a
                        [ href "https://creativecommons.org/licenses/by-sa/4.0/"
                        , rel "license"
                        ]
                        [ text "CC-BY-SA 4.0" ]
                    ]
                ]
            , button
                [ class "keymap-trigger"
                , css [ SidebarStyles.keymapTrigger ]
                , onClick actions.openKeymap
                , attribute "aria-label" "Keyboard shortcuts"
                , attribute "aria-haspopup" "dialog"
                , title "Keyboard shortcuts (?)"
                ]
                [ text "?" ]
            ]
        ]


pageOutline : Maybe String -> List Heading -> Html msg
pageOutline activeHeading headings =
    aside
        [ class "page-outline"
        , css [ OutlineStyles.pageOutline ]
        , attribute "aria-labelledby" "page-outline-title"
        ]
        [ h2 [ id "page-outline-title" ] [ text "ON THIS PAGE" ]
        , nav [ attribute "aria-label" "Table of contents", css [ OutlineStyles.links ] ]
            (List.map
                (\heading ->
                    a
                        [ href ("#" ++ heading.id)
                        , attribute "aria-current"
                            (if activeHeading == Just heading.id then
                                "location"

                             else
                                "false"
                            )
                        ]
                        [ text heading.label ]
                )
                headings
            )
        ]


categoryView : Actions msg -> State a -> String -> Html msg
categoryView actions model category =
    let
        children =
            [ span [ class "category-icon", css [ IconsStyles.categoryIcon ], attribute "aria-hidden" "true" ] [ text "▱" ]
            , span [ class "category-name", css [ SidebarStyles.categoryName ] ] [ text category ]
            , span [ class "count", css [ SidebarStyles.count ] ]
                [ text
                    (model.posts
                        |> List.filter (\post -> post.category == category)
                        |> List.length
                        |> String.fromInt
                    )
                ]
            ]

        attributes =
            [ css [ SidebarStyles.categoryItem ]
            , classList
                [ ( "category-item", True )
                , ( "active", model.category == category )
                ]
            ]
    in
    if model.page == "index" then
        button
            (attributes
                ++ [ onClick (actions.navigateCategory category)
                   , attribute "data-link-hint" category
                   , attribute "aria-pressed"
                        (if model.category == category then
                            "true"

                         else
                            "false"
                        )
                   ]
            )
            children

    else
        a
            (attributes ++ [ href ("/?category=" ++ Url.percentEncode category) ])
            children
