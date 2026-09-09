module Search exposing (matches)


matches : String -> { post | title : String, description : String, category : String, tags : List String } -> Bool
matches input post =
    let
        tokens =
            String.words (String.toLower input)

        ( category, terms ) =
            case tokens of
                first :: rest ->
                    if String.startsWith "/" first then
                        ( Just (String.dropLeft 1 first), rest )

                    else
                        ( Nothing, tokens )

                [] ->
                    ( Nothing, [] )

        searchableText =
            String.toLower (post.title ++ " " ++ post.description)

        matchesTerm term =
            if String.startsWith "#" term then
                List.any
                    (String.toLower >> String.startsWith (String.dropLeft 1 term))
                    post.tags

            else
                String.contains term searchableText
    in
    Maybe.withDefault True
        (Maybe.map (\prefix -> String.startsWith prefix (String.toLower post.category)) category)
        && List.all matchesTerm terms
