port module BrowserPorts exposing (browserReady, clearFocus, clearLinkHints, clockRefreshRequested, collectLinkHints, followLinkHint, keyboardPressed, linkHintsReady, linkTargetsChanged, linkTargetsCollected, observeReading, positionPage, probeLinkTargets, readingPositionChanged, refreshReading, replaceQuery, revealCurrentHeading, setKeyboardKeys, setPanel, setTheme, timingsChanged)

import Keyboard
import Layout exposing (PageTimings)
import LinkHints.Targets exposing (Activation, Candidate, Probe, Snapshot)
import Panels
import ReadingPosition


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


port followLinkHint : Activation -> Cmd msg


port linkHintsReady : (List Probe -> msg) -> Sub msg


port linkTargetsCollected : (Snapshot -> msg) -> Sub msg


port probeLinkTargets : List Candidate -> Cmd msg


port linkTargetsChanged : (() -> msg) -> Sub msg


port observeReading : List String -> Cmd msg


port readingPositionChanged : (ReadingPosition.Snapshot -> msg) -> Sub msg


port refreshReading : () -> Cmd msg


port revealCurrentHeading : () -> Cmd msg
