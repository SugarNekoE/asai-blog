module LinkHints exposing (Hint, view)

import Html exposing (Html, div, span, text)
import Html.Attributes exposing (attribute, class, style, title)


type alias Hint =
    { key : String
    , label : String
    , x : Float
    , y : Float
    }


view : String -> List Hint -> Html msg
view prefix hints =
    let
        matches =
            List.filter (\hint -> String.startsWith prefix hint.key) hints
    in
    div [ class "link-hints" ]
        (List.map
            (\hint ->
                span
                    [ class "link-hint"
                    , attribute "data-hint" hint.key
                    , title hint.label
                    , style "left" (String.fromFloat hint.x ++ "px")
                    , style "top" (String.fromFloat hint.y ++ "px")
                    ]
                    [ text (String.toUpper hint.key) ]
            )
            matches
            ++ [ div [ class "link-hint-status", attribute "role" "status" ]
                    [ text
                        ((if List.isEmpty hints then
                            "No visible links"

                          else if List.isEmpty matches then
                            "No matching hints — Backspace to retry"

                          else
                            "Open link: " ++ String.toUpper prefix
                         )
                            ++ " · type letters · Esc to cancel"
                        )
                    ]
               ]
        )
