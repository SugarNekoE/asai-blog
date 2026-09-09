port module BrowserPorts exposing (browserReady, clearFocus, clearLinkHints, clockRefreshRequested, collectLinkHints, followLinkHint, hintKey, keyboardPressed, linkHintsReady, replaceQuery, scrollNotebook, scrollSearchResult, setImmersiveMode, setKeyboardKeys, setKeymapOpen, setSearchOpen, setTheme, timingsChanged)

import Keyboard
import Layout exposing (PageTimings)
import LinkHints exposing (Target)


port setTheme : String -> Cmd msg


port setSearchOpen : Bool -> Cmd msg


port browserReady : (() -> msg) -> Sub msg


port setKeymapOpen : Bool -> Cmd msg


port keyboardPressed : (String -> msg) -> Sub msg


port scrollSearchResult : Int -> Cmd msg


port replaceQuery : String -> Cmd msg


port scrollNotebook : () -> Cmd msg


port clockRefreshRequested : (() -> msg) -> Sub msg


port timingsChanged : (PageTimings -> msg) -> Sub msg


port setKeyboardKeys : Keyboard.Keys -> Cmd msg


port clearFocus : () -> Cmd msg


port setImmersiveMode : Bool -> Cmd msg


port collectLinkHints : () -> Cmd msg


port clearLinkHints : () -> Cmd msg


port followLinkHint : Int -> Cmd msg


port linkHintsReady : (List Target -> msg) -> Sub msg


port hintKey : (String -> msg) -> Sub msg
