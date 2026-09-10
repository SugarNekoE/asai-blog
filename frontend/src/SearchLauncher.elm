module SearchLauncher exposing (Actions, State, results, view)

import Html.Styled as Html exposing (..)
import Html.Styled.Attributes exposing (..)
import Html.Styled.Events as Events exposing (onClick, onFocus, onInput, preventDefaultOn)
import Json.Decode as D
import Panels
import Post exposing (Post)
import Search as SearchQuery
import Styles.Dialog as DialogStyles


type alias State a =
    { a
        | posts : List Post
        , failed : Bool
        , panel : Panels.Panel
        , launcherQuery : String
        , launcherSelection : Int
    }


type alias Actions msg =
    { close : msg
    , query : String -> msg
    , move : Int -> msg
    , select : Int -> msg
    , open : msg
    }


matches : State a -> List Post
matches model =
    model.posts
        |> List.filter (SearchQuery.matches model.launcherQuery)
        |> List.sortBy .date
        |> List.reverse


results : State a -> List Post
results model =
    List.take 20 (matches model)


launcherKeys : Actions msg -> D.Decoder ( msg, Bool )
launcherKeys actions =
    D.field "key" D.string
        |> D.andThen
            (\key ->
                case key of
                    "Escape" ->
                        D.succeed ( actions.close, True )

                    "ArrowDown" ->
                        D.succeed ( actions.move 1, True )

                    "ArrowUp" ->
                        D.succeed ( actions.move -1, True )

                    "Enter" ->
                        D.at [ "target", "tagName" ] D.string
                            |> D.andThen
                                (\tag ->
                                    if tag == "BUTTON" then
                                        D.fail "Keep native button activation"

                                    else
                                        D.succeed ( actions.open, True )
                                )

                    _ ->
                        D.fail "Use the browser's normal key handling"
            )


view : Actions msg -> State a -> Html msg
view actions model =
    let
        matchingPosts =
            matches model

        visibleResults =
            List.take 20 matchingPosts
    in
    node "dialog"
        [ id "search-dialog"
        , attribute "data-panel-focus" "launcher-search"
        , class "search-dialog"
        , css [ DialogStyles.searchDialog ]
        , attribute "aria-labelledby" "search-dialog-title"
        , attribute "aria-modal" "true"
        , preventDefaultOn "cancel" (D.succeed ( actions.close, True ))
        , preventDefaultOn "keydown" (launcherKeys actions)
        , Events.on "click"
            (D.at [ "target", "id" ] D.string
                |> D.andThen
                    (\target ->
                        if target == "search-dialog" then
                            D.succeed actions.close

                        else
                            D.fail "Inside the panel"
                    )
            )
        ]
        [ div [ class "launcher-panel", css [ DialogStyles.launcherPanel ] ]
            [ div [ class "launcher-heading", css [ DialogStyles.launcherHeading ] ]
                [ h2 [ id "search-dialog-title" ] [ text "Search notes" ]
                , button
                    [ class "launcher-close"
                    , css [ DialogStyles.launcherClose ]
                    , onClick actions.close
                    , attribute "aria-label" "Close search"
                    ]
                    [ text "esc" ]
                ]
            , input
                [ id "launcher-search"
                , css [ DialogStyles.launcherSearch ]
                , type_ "search"
                , attribute "role" "combobox"
                , attribute "aria-label" "Search all notes"
                , attribute "aria-autocomplete" "list"
                , attribute "aria-controls" "launcher-results"
                , attribute "aria-describedby" "launcher-help"
                , attribute "aria-expanded"
                    (if model.panel == Panels.Search then
                        "true"

                     else
                        "false"
                    )
                , attribute "aria-activedescendant"
                    (if List.isEmpty visibleResults then
                        ""

                     else
                        "search-result-" ++ String.fromInt model.launcherSelection
                    )
                , autocomplete False
                , placeholder "Search titles, descriptions, #tags or /categories…"
                , value model.launcherQuery
                , onInput actions.query
                ]
                []
            , p [ id "launcher-help", class "launcher-help", css [ DialogStyles.launcherHelp ] ]
                [ text "Words search titles and descriptions. Use #tag or /category; combine them to narrow the results." ]
            , p [ class "launcher-count", css [ DialogStyles.launcherCount ], attribute "role" "status" ]
                [ text
                    (if model.failed then
                        "The search index is unavailable. Reload the page to try again."

                     else
                        String.fromInt (List.length matchingPosts)
                            ++ " matching notes"
                            ++ (if List.length matchingPosts > 20 then
                                    " · showing the first 20"

                                else
                                    ""
                               )
                    )
                ]
            , div
                [ id "launcher-results"
                , class "launcher-results"
                , css [ DialogStyles.launcherResults ]
                , attribute "role" "listbox"
                , attribute "aria-label" "Matching notes"
                ]
                (List.indexedMap (launcherResult actions model.launcherSelection) visibleResults)
            , if List.isEmpty visibleResults && not model.failed then
                p [ class "launcher-empty", css [ DialogStyles.launcherEmpty ] ] [ text "No notes match. Try another keyword, #tag, or /category." ]

              else
                text ""
            , div [ class "launcher-footer", css [ DialogStyles.launcherFooter ] ]
                [ text "↑ ↓ to navigate · enter to open · esc to close" ]
            ]
        ]


launcherResult : Actions msg -> Int -> Int -> Post -> Html msg
launcherResult actions active index post =
    a
        [ id ("search-result-" ++ String.fromInt index)
        , css [ DialogStyles.launcherResult ]
        , classList [ ( "launcher-result", True ), ( "is-selected", active == index ) ]
        , href post.url
        , attribute "role" "option"
        , attribute "aria-selected"
            (if active == index then
                "true"

             else
                "false"
            )
        , tabindex -1
        , onFocus (actions.select index)
        , Events.on "pointermove"
            (if active == index then
                D.fail "This result is already selected"

             else
                D.succeed (actions.select index)
            )
        ]
        [ span [ class "launcher-result-title", css [ DialogStyles.launcherResultTitle ] ] [ text post.title ]
        , span [ class "launcher-result-description", css [ DialogStyles.launcherResultDescription ] ] [ text post.description ]
        , span [ class "launcher-result-meta", css [ DialogStyles.launcherResultMeta ] ]
            (text ("/" ++ post.category ++ " · ")
                :: List.intersperse (text " ")
                    (List.map
                        (\tag ->
                            span [ class "launcher-tag", css [ DialogStyles.launcherTag ], attribute "data-tag" tag ] [ text ("#" ++ tag) ]
                        )
                        post.tags
                    )
            )
        ]
