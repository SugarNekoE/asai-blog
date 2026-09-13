module ReadingPosition exposing (Snapshot, current)


type alias HeadingPosition =
    { id : String, top : Float, scrollMargin : Float }


type alias Snapshot =
    { headings : List HeadingPosition
    , viewportHeight : Float
    , scrollTop : Float
    , documentHeight : Float
    , scrollPadding : Float
    }


current : Snapshot -> Maybe String
current snapshot =
    let
        reached =
            if snapshot.scrollTop > 0 && snapshot.scrollTop + snapshot.viewportHeight >= snapshot.documentHeight - 2 then
                snapshot.headings

            else
                List.filter
                    (\heading -> heading.top <= max 80 (snapshot.scrollPadding + heading.scrollMargin + 8))
                    snapshot.headings
    in
    case List.head (List.reverse reached) of
        Just heading ->
            Just heading.id

        Nothing ->
            List.head snapshot.headings |> Maybe.map .id
