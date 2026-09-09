module Notebook exposing (view)

import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (..)
import Html.Styled.Events exposing (onClick, onInput)
import Notebook.Card as Card
import Notebook.Filters as Filters
import Notebook.Pagination as Pagination
import Notebook.Query as Query
import Notebook.Types exposing (Actions, State)
import Set
import Styles.Filters as FiltersStyles
import Styles.Icons as IconsStyles
import Styles.Intro as IntroStyles


view : Actions msg -> State a -> Html msg
view actions model =
    let
        posts =
            Query.indexPosts model

        offset =
            (model.indexPage - 1) * model.pageSize

        visiblePosts =
            Query.visibleIndexNotes model
    in
    div []
        [ header [ class "intro", css [ IntroStyles.intro ] ]
            [ p
                [ class "eyebrow"
                ]
                [ span
                    [ class "accent"
                    ]
                    [ text "~/"
                    ]
                , text " A PERSONAL KNOWLEDGE BASE"
                ]
            , h1
                []
                [ text "Thinking in "
                , em
                    []
                    [ text "systems."
                    ]
                , br
                    []
                    []
                , text "Writing in plain text."
                ]
            , p
                [ class "intro-description"
                , css [ IntroStyles.introDescription ]
                ]
                [ text "Field notes on code, tools, and the things in between."
                , br
                    []
                    []
                , text "A little less noise. A little more understanding."
                ]
            , div
                [ class "intro-meta"
                , css [ IntroStyles.introMeta ]
                ]
                [ span
                    []
                    [ span
                        [ class "dot"
                        , css [ IntroStyles.dot ]
                        ]
                        []
                    , text "learning in public"
                    ]
                , span
                    []
                    [ text "//"
                    ]
                , span
                    []
                    [ text (String.fromInt (List.length model.posts) ++ " notes and counting")
                    ]
                ]
            ]
        , div
            [ class "collection-header"
            , css [ IntroStyles.collectionHeader ]
            ]
            [ h2
                [ id "notebook-heading", tabindex -1 ]
                [ text "The notebook"
                , span
                    [ class "muted"
                    ]
                    [ text " /"
                    ]
                ]
            , span
                [ class "eyebrow"
                ]
                [ text "IDEAS, COMMITTED."
                ]
            ]
        , div [ class "filterbar", css [ FiltersStyles.filterbar ] ]
            [ Filters.view actions model
            , button [ class "sort-button", css [ FiltersStyles.sortButton ], onClick actions.toggleSort ]
                [ span [ class "symbol", css [ IconsStyles.symbol ], attribute "aria-hidden" "true" ]
                    [ text
                        (if model.oldest then
                            "↑"

                         else
                            "↓"
                        )
                    ]
                , text
                    (if model.oldest then
                        "Oldest first"

                     else
                        "Newest first"
                    )
                ]
            ]
        , div
            [ class "search-field"
            , css [ FiltersStyles.searchField ]
            ]
            [ span
                [ class "symbol search-icon"
                , css [ IconsStyles.symbol, IconsStyles.searchIcon ]
                , attribute "aria-hidden" "true"
                ]
                [ text "⌕"
                ]
            , input
                [ id "note-search"
                , type_ "search"
                , placeholder "Find something..."
                , attribute "aria-label" "Search notes"
                , value model.query
                , onInput actions.search
                ]
                []
            , kbd
                []
                [ text "/"
                ]
            ]
        , p [ class "result-count", css [ IntroStyles.resultCount ], attribute "role" "status" ]
            [ text
                (String.fromInt (List.length posts)
                    ++ (if List.length posts == 1 then
                            " note"

                        else
                            " notes"
                       )
                    ++ (if String.isEmpty model.query && Set.isEmpty model.selectedTags then
                            if String.isEmpty model.category then
                                " in the notebook"

                            else
                                " in " ++ model.category

                        else
                            " found"
                       )
                )
            ]
        , if List.isEmpty posts then
            div
                [ class "empty-state"
                , css [ IntroStyles.emptyState ]
                ]
                [ span
                    [ class "accent"
                    ]
                    [ text "∅"
                    ]
                , h3
                    []
                    [ text "No notes on this path. Yet."
                    ]
                , p
                    []
                    [ text "Try another keyword, remove a tag, or choose a different category."
                    ]
                , if Set.isEmpty model.selectedTags then
                    text ""

                  else
                    button
                        [ class "reset-button", css [ IntroStyles.resetButton ], onClick actions.clearTags ]
                        [ text "Clear filters →" ]
                , if String.isEmpty model.query then
                    text ""

                  else
                    button
                        [ class "reset-button", css [ IntroStyles.resetButton ], onClick (actions.search "") ]
                        [ text "Clear search" ]
                ]

          else
            div [ class "post-list" ]
                (List.indexedMap (\index post -> Card.view actions model.selectedTags (Maybe.map .url (Query.selectedIndexNote model)) (offset + index) post) visiblePosts)
        , Pagination.view actions model (List.length posts)
        , if not (List.isEmpty posts) && model.indexPage == Query.pageCount model then
            div [ class "notebook-end", css [ IntroStyles.notebookEnd ] ] [ text "You've reached the edge of the notebook." ]

          else
            text ""
        ]
