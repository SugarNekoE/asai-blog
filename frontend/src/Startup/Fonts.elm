module Startup.Fonts exposing (Request, requests)

import Char


type alias Request =
    { font : String, sample : String }


requests : String -> List Request
requests sample =
    let
        cjk =
            String.filter (\character -> Char.toCode character >= 0x3000) sample
    in
    [ Request "400 16px \"Noto Sans\"" sample
    , Request "italic 400 16px \"Noto Sans\"" sample
    , Request "400 16px \"Noto Sans Mono\"" sample
    , Request "400 16px \"Noto Sans CJK SC\"" cjk
    , Request "400 16px \"Noto Sans Mono CJK SC\"" cjk
    , Request "400 20px \"Noto Sans Symbols\"" "↗"
    , Request "400 20px \"Noto Sans Symbols 2\"" "◐☼"
    ]
