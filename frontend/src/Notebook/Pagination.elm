module Notebook.Pagination exposing (view)

import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (..)
import Html.Styled.Events exposing (onClick, onInput)
import Notebook.Query as Query
import Notebook.Types exposing (Actions, State)
import Set
import Styles.Pagination as PaginationStyles


view : Actions msg -> State a -> Int -> Html msg
view actions model total =
    let
        count =
            Query.pageCount model

        numbers =
            [ 1, model.indexPage - 1, model.indexPage, model.indexPage + 1, count ]
                |> List.filter (\number -> number >= 1 && number <= count)
                |> Set.fromList
                |> Set.toList

        first =
            (model.indexPage - 1) * model.pageSize + 1
    in
    div [ class "pagination", css [ PaginationStyles.pagination ] ]
        [ div [ class "pagination-settings", css [ PaginationStyles.paginationSettings ] ]
            [ label [ for "notes-per-page" ] [ text "Notes per page" ]
            , select [ id "notes-per-page", onInput actions.setPageSize ]
                (List.map
                    (\size ->
                        option
                            [ attribute "value" (String.fromInt size)
                            , selected (size == model.pageSize)
                            ]
                            [ text (String.fromInt size) ]
                    )
                    [ 10, 30, 50, 100 ]
                )
            ]
        , span [ class "pagination-summary", css [ PaginationStyles.paginationSummary ], attribute "aria-live" "polite" ]
            [ text
                (if total == 0 then
                    "0 notes"

                 else
                    String.fromInt first
                        ++ "–"
                        ++ String.fromInt (Basics.min total (first + model.pageSize - 1))
                        ++ " of "
                        ++ String.fromInt total
                        ++ " notes"
                )
            ]
        , nav [ class "pagination-controls", css [ PaginationStyles.paginationControls ], attribute "aria-label" "Notes pagination" ]
            [ button
                [ onClick (actions.goToPage (model.indexPage - 1))
                , disabled (model.indexPage <= 1)
                ]
                [ text "Previous" ]
            , div [ class "pagination-pages", css [ PaginationStyles.paginationPages ] ]
                (List.indexedMap
                    (\index number ->
                        let
                            previous =
                                List.drop (index - 1) numbers |> List.head |> Maybe.withDefault 0
                        in
                        span [ class "pagination-step", css [ PaginationStyles.paginationStep ] ]
                            [ if index > 0 && number > previous + 1 then
                                span [ class "pagination-gap", css [ PaginationStyles.paginationGap ], attribute "aria-hidden" "true" ] [ text "…" ]

                              else
                                text ""
                            , button
                                [ onClick (actions.goToPage number)
                                , attribute "aria-label" ("Go to page " ++ String.fromInt number)
                                , attribute "aria-current"
                                    (if model.indexPage == number then
                                        "page"

                                     else
                                        "false"
                                    )
                                ]
                                [ text (String.fromInt number) ]
                            ]
                    )
                    numbers
                )
            , button
                [ onClick (actions.goToPage (model.indexPage + 1))
                , disabled (model.indexPage >= count)
                ]
                [ text "Next" ]
            ]
        ]
