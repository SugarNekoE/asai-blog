module Styles.Responsive exposing (rules)

import Css exposing (Style, batch)
import Css.Media as Media


rules : List ( String, List Style ) -> Style
rules queries =
    -- elm-css 18 emits sibling media queries in reverse order.
    queries
        |> List.reverse
        |> List.map (\( query, styles ) -> Media.withMediaQuery [ query ] styles)
        |> batch
