module Styles.Typography exposing (mono, monoNormal, symbols)

import Css exposing (Style, property)


mono : Float -> Float -> Style
mono size height =
    property "font" (String.fromFloat size ++ "px/" ++ String.fromFloat height ++ " var(--mono)")


monoNormal : Float -> Style
monoNormal size =
    property "font" (String.fromFloat size ++ "px" ++ " var(--mono)")


symbols : Float -> Float -> Style
symbols size height =
    property "font" (String.fromFloat size ++ "px/" ++ String.fromFloat height ++ " var(--symbols)")
