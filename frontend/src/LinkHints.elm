module LinkHints exposing (Hint, Target, assign, view)

import Array
import Html.Styled as Html exposing (Html, div, span, text)
import Html.Styled.Attributes exposing (attribute, class, css, style, title)
import Styles.Hints as HintsStyles


type alias Hint =
    { id : Int
    , key : String
    , label : String
    , x : Float
    , y : Float
    }


type alias Target =
    { id : Int
    , label : String
    , x : Float
    , y : Float
    }


assign : List Target -> List Hint
assign targets =
    let
        alphabet =
            Array.fromList (String.toList "asdfghjkl")

        base =
            Array.length alphabet

        width capacity digits =
            if capacity >= List.length targets then
                digits

            else
                width (capacity * base) (digits + 1)

        key digits number =
            if digits == 0 then
                ""

            else
                key (digits - 1) (number // base)
                    ++ (Array.get (modBy base number) alphabet
                            |> Maybe.withDefault 'a'
                            |> String.fromChar
                       )

        labelWidth =
            width base 1
    in
    List.indexedMap
        (\index target ->
            { id = target.id
            , key = key labelWidth index
            , label = target.label
            , x = target.x
            , y = target.y
            }
        )
        targets


view : String -> List Hint -> Html msg
view prefix hints =
    let
        matches =
            List.filter (\hint -> String.startsWith prefix hint.key) hints
    in
    div [ class "link-hints", css [ HintsStyles.linkHints ] ]
        (List.map
            (\hint ->
                span
                    [ class "link-hint"
                    , css [ HintsStyles.linkHint ]
                    , attribute "data-hint" hint.key
                    , title hint.label
                    , style "left" (String.fromFloat hint.x ++ "px")
                    , style "top" (String.fromFloat hint.y ++ "px")
                    ]
                    [ text (String.toUpper hint.key) ]
            )
            matches
            ++ [ div [ class "link-hint-status", css [ HintsStyles.linkHintStatus ], attribute "role" "status" ]
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
