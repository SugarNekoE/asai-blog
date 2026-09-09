module Keyboard exposing (Action(..), Keys, action, context, keys)


type Action
    = Theme
    | Outline
    | Immersive
    | Hints
    | OpenNote
    | Search
    | Keymap
    | ClearFocus
    | HintInput String
    | None


type alias Context a =
    { a | page : String, hintsActive : Bool, launcherOpen : Bool, keymapOpen : Bool }


type alias Keys =
    { page : List String
    , control : List String
    , editing : List String
    }


context : Context a -> ( Bool, Bool, Bool )
context model =
    ( model.hintsActive, model.launcherOpen, model.keymapOpen )


shortcuts : List ( String, Action )
shortcuts =
    [ ( "t", Theme )
    , ( "o", Outline )
    , ( "Shift+I", Immersive )
    , ( "f", Hints )
    , ( "Enter", OpenNote )
    , ( "/", Search )
    , ( "?", Keymap )
    , ( "Escape", ClearFocus )
    ]


keys : Context a -> Keys
keys model =
    let
        available =
            activeKeys model

        allowed key =
            key /= "Shift+I" || model.page == "post"
    in
    { page = List.filter allowed available.page
    , control = List.filter allowed available.control
    , editing = available.editing
    }


activeKeys : Context a -> Keys
activeKeys model =
    if model.hintsActive then
        let
            letters =
                String.toList "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
                    |> List.map String.fromChar

            hintKeys =
                "Escape" :: "Backspace" :: letters
        in
        { page = "Shift+I" :: hintKeys
        , control = "Shift+I" :: hintKeys
        , editing = hintKeys
        }

    else if model.launcherOpen || model.keymapOpen then
        { page = [ "/", "?", "Shift+I" ]
        , control = [ "/", "?", "Shift+I" ]
        , editing = []
        }

    else
        { page = List.map Tuple.first shortcuts
        , control = List.map Tuple.first shortcuts |> List.filter ((/=) "Enter")
        , editing = [ "Escape" ]
        }


action : Context a -> String -> Action
action model key =
    if key == "Shift+I" then
        if model.page == "post" then
            Immersive

        else
            None

    else if model.hintsActive then
        HintInput key

    else
        shortcuts
            |> List.filter (Tuple.first >> (==) key)
            |> List.head
            |> Maybe.map Tuple.second
            |> Maybe.withDefault None
