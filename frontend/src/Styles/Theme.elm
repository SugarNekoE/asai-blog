module Styles.Theme exposing (Token(..), background, borderColor, color, outlineColor)

import Css exposing (Style, property)


type Token
    = Accent
    | ActiveBackground
    | Backdrop
    | Bg
    | Border
    | CategoryColor
    | Faint
    | HintBackground
    | HintText
    | Hover
    | Muted
    | Sidebar
    | Surface
    | TagColor
    | Text


value : Token -> String
value token =
    case token of
        Accent ->
            "var(--accent)"

        ActiveBackground ->
            "var(--active-background)"

        Backdrop ->
            "var(--backdrop)"

        Bg ->
            "var(--bg)"

        Border ->
            "var(--border)"

        CategoryColor ->
            "var(--category-color)"

        Faint ->
            "var(--faint)"

        HintBackground ->
            "var(--hint-background)"

        HintText ->
            "var(--hint-text)"

        Hover ->
            "var(--hover)"

        Muted ->
            "var(--muted)"

        Sidebar ->
            "var(--sidebar)"

        Surface ->
            "var(--surface)"

        TagColor ->
            "var(--tag-color)"

        Text ->
            "var(--text)"


color : Token -> Style
color token =
    property "color" (value token)


background : Token -> Style
background token =
    property "background" (value token)


borderColor : Token -> Style
borderColor token =
    property "border-color" (value token)


outlineColor : Token -> Style
outlineColor token =
    property "outline-color" (value token)
