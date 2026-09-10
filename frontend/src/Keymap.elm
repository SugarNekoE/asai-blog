module Keymap exposing (view)

import Html.Styled as Html exposing (..)
import Html.Styled.Attributes exposing (..)
import Html.Styled.Events as Events exposing (onClick, preventDefaultOn)
import Json.Decode as D
import Styles.Dialog as DialogStyles
import Styles.Keymap as KeymapStyles


view : msg -> Html msg
view close =
    node "dialog"
        [ id "keymap-dialog"
        , attribute "data-panel-focus" "keymap-close"
        , class "search-dialog keymap-dialog"
        , css [ DialogStyles.searchDialog, KeymapStyles.keymapDialog ]
        , attribute "aria-labelledby" "keymap-title"
        , attribute "aria-modal" "true"
        , preventDefaultOn "cancel" (D.succeed ( close, True ))
        , preventDefaultOn "keydown"
            (D.field "key" D.string
                |> D.andThen
                    (\key ->
                        if key == "Escape" then
                            D.succeed ( close, True )

                        else
                            D.fail "Other key"
                    )
            )
        , Events.on "click"
            (D.at [ "target", "id" ] D.string
                |> D.andThen
                    (\target ->
                        if target == "keymap-dialog" then
                            D.succeed close

                        else
                            D.fail "Inside the panel"
                    )
            )
        ]
        [ div [ class "launcher-panel", css [ DialogStyles.launcherPanel ] ]
            [ div [ class "launcher-heading", css [ DialogStyles.launcherHeading ] ]
                [ h2 [ id "keymap-title" ] [ text "Keyboard shortcuts" ]
                , button
                    [ id "keymap-close"
                    , class "launcher-close"
                    , css [ DialogStyles.launcherClose ]
                    , onClick close
                    , attribute "aria-label" "Close keyboard shortcuts"
                    ]
                    [ text "esc" ]
                ]
            , p [ class "launcher-help", css [ DialogStyles.launcherHelp ] ] [ text "Use page shortcuts outside text fields. Tab to a note title or hover a note to select it." ]
            , dl [ class "keymap-list", css [ KeymapStyles.keymapList ] ]
                (List.map
                    (\( keys, description ) ->
                        div [ class "keymap-row", css [ KeymapStyles.keymapRow ] ]
                            [ dt [] [ kbd [] [ text keys ] ]
                            , dd [] [ text description ]
                            ]
                    )
                    [ ( "?", "Open keyboard shortcuts" )
                    , ( "/", "Open search" )
                    , ( "t", "Toggle theme" )
                    , ( "o", "Show or hide the article’s table of contents" )
                    , ( "Shift + I", "Toggle Immersive Mode on a note" )
                    , ( "f", "Show letter hints for links and categories" )
                    , ( "Esc", "Close panel, cancel hints, or clear focus" )
                    , ( "Backspace", "Remove the last hint letter" )
                    , ( "↑ / ↓", "Select a search result" )
                    , ( "Enter", "Open the selected note or search result" )
                    , ( "Tab / Shift + Tab", "Move between panel controls" )
                    ]
                )
            ]
        ]
