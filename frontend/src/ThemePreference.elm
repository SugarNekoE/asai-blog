module ThemePreference exposing (Preference, description, fromString, icon, next, toString)


type Preference
    = Auto
    | Light
    | Dark


fromString : String -> Preference
fromString value =
    case value of
        "light" ->
            Light

        "dark" ->
            Dark

        _ ->
            Auto


toString : Preference -> String
toString preference =
    case preference of
        Auto ->
            "auto"

        Light ->
            "light"

        Dark ->
            "dark"


next : Preference -> Preference
next preference =
    case preference of
        Auto ->
            Light

        Light ->
            Dark

        Dark ->
            Auto


description : Preference -> String
description preference =
    case preference of
        Auto ->
            "Theme: Auto (system). Switch to Light."

        Light ->
            "Theme: Light. Switch to Dark."

        Dark ->
            "Theme: Dark. Switch to Auto."


icon : Preference -> String
icon preference =
    case preference of
        Auto ->
            "◐"

        Light ->
            "☼"

        Dark ->
            "☾"
