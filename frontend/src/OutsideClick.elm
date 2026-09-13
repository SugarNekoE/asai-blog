module OutsideClick exposing (excluding)

import Json.Decode as D


excluding : List String -> msg -> D.Decoder msg
excluding ids close =
    D.field "target" (inside ids)
        |> D.andThen
            (\isInside ->
                if isInside then
                    D.fail "Keep the control open"

                else
                    D.succeed close
            )


inside : List String -> D.Decoder Bool
inside ids =
    D.oneOf
        [ D.field "id" D.string
            |> D.andThen
                (\identifier ->
                    if List.member identifier ids then
                        D.succeed True

                    else
                        D.fail "Check the parent"
                )
        , D.field "parentNode" (D.lazy (\_ -> inside ids))
        , D.succeed False
        ]
