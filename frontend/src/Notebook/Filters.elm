module Notebook.Filters exposing (view)

import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (..)
import Html.Styled.Events exposing (on, onCheck, onClick)
import Json.Decode as D
import Json.Encode as E
import Notebook.Types exposing (Actions, State)
import Set
import Styles.Filters as FiltersStyles


view : Actions msg -> State a -> Html msg
view actions model =
    let
        availableTags =
            model.posts
                |> List.concatMap .tags
                |> Set.fromList
                |> Set.toList
    in
    div [ class "index-filters", css [ FiltersStyles.indexFilters ] ]
        [ details
            [ id "tag-picker"
            , class "tag-picker"
            , css [ FiltersStyles.tagPicker ]
            , property "open" (E.bool model.tagPickerOpen)
            , on "toggle" (D.map actions.setTagPicker (D.at [ "target", "open" ] D.bool))
            ]
            [ summary []
                [ text "Tags"
                , span [ class "tag-selection-count", css [ FiltersStyles.tagSelectionCount ] ]
                    [ text (String.fromInt (Set.size model.selectedTags)) ]
                ]
            , div
                [ class "tag-options"
                , css [ FiltersStyles.tagOptions ]
                , attribute "role" "group"
                , attribute "aria-label" "Available tags"
                ]
                (p [ class "filter-mode", css [ FiltersStyles.filterMode ] ] [ text "Match all selected tags" ]
                    :: List.map
                        (\tag ->
                            label [ class "tag-option", css [ FiltersStyles.tagOption ], attribute "data-tag" tag ]
                                [ input
                                    [ type_ "checkbox"
                                    , checked (Set.member tag model.selectedTags)
                                    , onCheck (actions.setTag tag)
                                    , attribute "aria-label" ("Select tag " ++ tag)
                                    ]
                                    []
                                , span [] [ text ("# " ++ tag) ]
                                ]
                        )
                        availableTags
                )
            ]
        , div
            [ class "selected-tags"
            , css [ FiltersStyles.selectedTags ]
            , attribute "role" "group"
            , attribute "aria-label" "Selected tags"
            ]
            (model.selectedTags
                |> Set.toList
                |> List.map
                    (\tag ->
                        button
                            [ class "selected-tag"
                            , css [ FiltersStyles.selectedTag ]
                            , attribute "data-tag" tag
                            , onClick (actions.setTag tag False)
                            , attribute "aria-label" ("Remove tag " ++ tag)
                            ]
                            [ text ("# " ++ tag)
                            , span [ attribute "aria-hidden" "true" ] [ text "×" ]
                            ]
                    )
            )
        , if Set.isEmpty model.selectedTags then
            text ""

          else
            button [ class "clear-filters", css [ FiltersStyles.clearFilters ], onClick actions.clearTags ] [ text "Clear filters" ]
        ]
