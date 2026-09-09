module Notebook.Card exposing (view)

import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (..)
import Html.Styled.Events exposing (onClick, onFocus, onMouseEnter)
import Notebook.Types exposing (Actions)
import Post exposing (Post)
import Set
import Styles.Notes as NotesStyles


view : Actions msg -> Set.Set String -> Maybe String -> Int -> Post -> Html msg
view actions selectedTags selectedNote index post =
    article
        [ css [ NotesStyles.postRow ]
        , classList [ ( "post-row", True ), ( "is-selected", selectedNote == Just post.url ) ]
        , onMouseEnter (actions.selectNote post.url)
        ]
        [ div
            [ class "post-date"
            , css [ NotesStyles.postDate ]
            ]
            [ time
                [ datetime post.date
                ]
                [ text (String.dropLeft 5 post.date |> String.replace "-" ".")
                ]
            , small
                []
                [ text (String.left 4 post.date)
                ]
            ]
        , div [ class "post-details", css [ NotesStyles.postDetails ] ]
            [ div
                [ class "post-kicker"
                , css [ NotesStyles.postKicker ]
                ]
                [ text ("NOTE " ++ String.padLeft 2 '0' (String.fromInt (index + 1)))
                , span [ class "post-category", css [ NotesStyles.postCategory ] ] [ text post.category ]
                , span
                    [ class "read-time"
                    , css [ NotesStyles.readTime ]
                    ]
                    [ text (String.fromInt post.readingMinutes ++ " min read")
                    ]
                ]
            , h3
                []
                [ a
                    [ href post.url
                    , onFocus (actions.selectNote post.url)
                    ]
                    [ text post.title
                    , span
                        [ class "post-arrow"
                        , css [ NotesStyles.postArrow ]
                        ]
                        [ text "↗"
                        ]
                    ]
                ]
            , p [] [ text post.description ]
            , div
                [ class "tags"
                , css [ NotesStyles.tags ]
                ]
                (List.map
                    (\tag ->
                        button
                            [ class "tag"
                            , css [ NotesStyles.tag ]
                            , attribute "data-tag" tag
                            , onClick (actions.setTag tag True)
                            , attribute "aria-label" ("Filter by tag " ++ tag)
                            , attribute "aria-pressed"
                                (if Set.member tag selectedTags then
                                    "true"

                                 else
                                    "false"
                                )
                            ]
                            [ text ("# " ++ tag)
                            ]
                    )
                    post.tags
                )
            ]
        ]
