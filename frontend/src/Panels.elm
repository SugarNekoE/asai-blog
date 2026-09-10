module Panels exposing (Panel(..), Position, Target, notebook, reading, searchResult, target)


type Panel
    = Closed
    | Search
    | Keymap


type alias Target =
    { id : String, focusId : String }


type alias Position =
    { id : String, focusId : String, block : String }


target : Panel -> Target
target panel =
    case panel of
        Closed ->
            Target "" ""

        Search ->
            Target "search-dialog" "launcher-search"

        Keymap ->
            Target "keymap-dialog" "keymap-close"


searchResult : Int -> Position
searchResult index =
    Position ("search-result-" ++ String.fromInt index) "launcher-search" "nearest"


notebook : Position
notebook =
    Position "notebook-heading" "notebook-heading" "start"


reading : Position
reading =
    Position "" "main" "start"
