port module Startup exposing (main)

import Http
import Platform
import Post exposing (Post)
import Process
import Startup.Fonts as Fonts
import Task


port startupBegin : (String -> msg) -> Sub msg


port assetSettled : (String -> msg) -> Sub msg


port loadFonts : List Fonts.Request -> Cmd msg


port startupStage : String -> Cmd msg


port startupReady : List Post -> Cmd msg


port startupFailed : () -> Cmd msg


type Phase
    = Idle
    | Waiting
    | Finished


type alias Model =
    { indexUrl : String
    , phase : Phase
    , fonts : Bool
    , assets : Bool
    , index : Maybe (List Post)
    }


type Msg
    = Begin String
    | Settled String
    | IndexLoaded (Result Http.Error (List Post))
    | Timeout


main : Program String Model Msg
main =
    Platform.worker
        { init = \url -> ( Model url Idle False False Nothing, Cmd.none )
        , update = update
        , subscriptions =
            \model ->
                if model.phase == Finished then
                    Sub.none

                else
                    Sub.batch [ startupBegin Begin, assetSettled Settled ]
        }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case ( model.phase, msg ) of
        ( Idle, Begin sample ) ->
            ( { model | phase = Waiting }
            , Cmd.batch
                [ loadFonts (Fonts.requests sample)
                , startupStage "loading fonts..."
                , Http.get
                    { url = model.indexUrl
                    , expect = Http.expectJson IndexLoaded Post.indexDecoder
                    }
                , Process.sleep 15000 |> Task.perform (always Timeout)
                ]
            )

        ( Waiting, IndexLoaded (Ok index) ) ->
            advance { model | index = Just index }

        ( Waiting, IndexLoaded (Err _) ) ->
            fail model

        ( Waiting, Timeout ) ->
            fail model

        ( _, Settled resource ) ->
            advance
                { model
                    | fonts = model.fonts || resource == "fonts"
                    , assets = model.assets || resource == "assets"
                }

        _ ->
            ( model, Cmd.none )


fail : Model -> ( Model, Cmd Msg )
fail model =
    ( { model | phase = Finished, index = Nothing }, startupFailed () )


advance : Model -> ( Model, Cmd Msg )
advance model =
    if model.phase /= Waiting then
        ( model, Cmd.none )

    else
        case ( model.fonts, model.index, model.assets ) of
            ( True, Just index, True ) ->
                ( { model | phase = Finished, index = Nothing }
                , Cmd.batch [ startupStage "rendering page...", startupReady index ]
                )

            _ ->
                ( model
                , startupStage
                    (if not model.fonts then
                        "loading fonts..."

                     else if model.index == Nothing then
                        "loading notes..."

                     else
                        "loading assets..."
                    )
                )
