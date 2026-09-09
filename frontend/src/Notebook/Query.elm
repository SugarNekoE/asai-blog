module Notebook.Query exposing (indexPosts, pageCount, selectedIndexNote, visibleIndexNotes)

import Notebook.Types exposing (State)
import Post exposing (Post)
import Set


indexPosts : State a -> List Post
indexPosts model =
    let
        categoryPosts =
            List.filter
                (\post -> String.isEmpty model.category || post.category == model.category)
                model.posts

        matches post =
            List.all (\tag -> List.member tag post.tags) (Set.toList model.selectedTags)
                && List.all
                    (\word ->
                        String.contains word
                            (String.toLower
                                (post.title
                                    ++ " "
                                    ++ post.description
                                    ++ " "
                                    ++ String.join " " post.tags
                                    ++ " "
                                    ++ post.searchText
                                )
                            )
                    )
                    (String.words (String.toLower model.query))

        filtered =
            List.filter matches categoryPosts |> List.sortBy .date
    in
    if model.oldest then
        filtered

    else
        List.reverse filtered


visibleIndexNotes : State a -> List Post
visibleIndexNotes model =
    indexPosts model
        |> List.drop ((model.indexPage - 1) * model.pageSize)
        |> List.take model.pageSize


selectedIndexNote : State a -> Maybe Post
selectedIndexNote model =
    let
        notes =
            visibleIndexNotes model
    in
    case List.filter (\post -> Just post.url == model.selectedNote) notes |> List.head of
        Just post ->
            Just post

        Nothing ->
            List.head notes


pageCount : State a -> Int
pageCount model =
    Basics.max 1 ((List.length (indexPosts model) + model.pageSize - 1) // model.pageSize)
