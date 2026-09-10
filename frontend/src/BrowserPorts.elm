port module BrowserPorts exposing (browserReady, clearFocus, clearLinkHints, clockRefreshRequested, collectLinkHints, followLinkHint, hintKey, keyboardPressed, linkHintsReady, positionPage, replaceQuery, setKeyboardKeys, setPanel, setTheme, timingsChanged)

import Keyboard
import Layout exposing (PageTimings)
import LinkHints exposing (Target)
import Panels


port setTheme : String -> Cmd msg


port setPanel : Panels.Target -> Cmd msg


port browserReady : (() -> msg) -> Sub msg


port keyboardPressed : (String -> msg) -> Sub msg


port positionPage : Panels.Position -> Cmd msg


port replaceQuery : String -> Cmd msg


port clockRefreshRequested : (() -> msg) -> Sub msg


port timingsChanged : (PageTimings -> msg) -> Sub msg


port setKeyboardKeys : Keyboard.Keys -> Cmd msg


port clearFocus : () -> Cmd msg


port collectLinkHints : () -> Cmd msg


port clearLinkHints : () -> Cmd msg


port followLinkHint : Int -> Cmd msg


port linkHintsReady : (List Target -> msg) -> Sub msg


port hintKey : (String -> msg) -> Sub msg
