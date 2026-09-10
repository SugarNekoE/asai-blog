port module CodeBlock exposing (main)

import Browser
import Html.Styled as Html exposing (Html, button, text)
import Html.Styled.Attributes exposing (attribute, class, type_)
import Html.Styled.Events exposing (onClick)
import Process
import Task


port copyCode : () -> Cmd msg


port copyCompleted : (Bool -> msg) -> Sub msg


type Status
    = Idle
    | Copying
    | Copied
    | Failed


type alias Model =
    { status : Status, attempt : Int }


type Msg
    = Copy
    | Completed Bool
    | Reset Int


main : Program () Model Msg
main =
    Browser.element
        { init = \_ -> ( Model Idle 0, Cmd.none )
        , update = update
        , view = view >> Html.toUnstyled
        , subscriptions = always (copyCompleted Completed)
        }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Copy ->
            if model.status == Copying then
                ( model, Cmd.none )

            else
                ( { status = Copying, attempt = model.attempt + 1 }, copyCode () )

        Completed success ->
            ( { model
                | status =
                    if success then
                        Copied

                    else
                        Failed
              }
            , Process.sleep 2500 |> Task.perform (always (Reset model.attempt))
            )

        Reset attempt ->
            ( if attempt == model.attempt then
                { model | status = Idle }

              else
                model
            , Cmd.none
            )


view : Model -> Html Msg
view model =
    let
        ( label, accessible, state ) =
            case model.status of
                Idle ->
                    ( "Copy", "Copy code", [] )

                Copying ->
                    ( "Copying…", "Copy code", [ attribute "data-state" "copying", attribute "aria-busy" "true" ] )

                Copied ->
                    ( "Copied", "Code copied", [ attribute "data-state" "copied" ] )

                Failed ->
                    ( "Copy failed", "Copy failed. Select the code and copy it manually.", [ attribute "data-state" "failed" ] )
    in
    button
        ([ type_ "button"
         , class "code-copy"
         , attribute "aria-label" accessible
         , attribute "aria-live" "polite"
         , onClick Copy
         ]
            ++ state
        )
        [ text label ]
