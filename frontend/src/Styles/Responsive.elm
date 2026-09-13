module Styles.Responsive exposing (mobileTopbarHeight, outlineBreakpoint, outlineNarrow, rules)

import Css exposing (Style, batch)
import Css.Media as Media


mobileTopbarHeight : Float
mobileTopbarHeight =
    60


outlineBreakpoint : Int
outlineBreakpoint =
    1600


outlineNarrow : String
outlineNarrow =
    "(max-width: " ++ String.fromInt (outlineBreakpoint - 1) ++ "px)"


rules : List ( String, List Style ) -> Style
rules queries =
    -- elm-css 18 emits sibling media queries in reverse order.
    queries
        |> List.reverse
        |> List.map (\( query, styles ) -> Media.withMediaQuery [ query ] styles)
        |> batch
