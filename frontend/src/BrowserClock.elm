module BrowserClock exposing (Clock, Sample, fromBrowser, nextTick, read)

import Process
import Task exposing (Task)
import Time exposing (Month(..), Posix, Zone)


type alias Clock =
    { label : String
    , iso : String
    }


type alias Sample =
    { now : Int
    , offset : Int
    }


fromBrowser : Sample -> Clock
fromBrowser sample =
    format (Time.customZone (negate sample.offset) []) (Time.millisToPosix sample.now)


read : Task Never Clock
read =
    Task.map2 format Time.here Time.now


nextTick : (Clock -> msg) -> Cmd msg
nextTick toMsg =
    Time.now
        |> Task.andThen
            (\now ->
                Process.sleep (toFloat (60000 - modBy 60000 (Time.posixToMillis now)))
            )
        |> Task.andThen (\_ -> read)
        |> Task.perform toMsg


format : Zone -> Posix -> Clock
format zone now =
    { label = date "/" zone now ++ " " ++ hour zone now
    , iso =
        date "-" Time.utc now
            ++ "T"
            ++ hour Time.utc now
            ++ ":"
            ++ pad 2 (Time.toSecond Time.utc now)
            ++ "."
            ++ pad 3 (Time.toMillis Time.utc now)
            ++ "Z"
    }


date : String -> Zone -> Posix -> String
date separator zone now =
    String.join separator
        [ pad 4 (Time.toYear zone now)
        , pad 2 (monthNumber (Time.toMonth zone now))
        , pad 2 (Time.toDay zone now)
        ]


hour : Zone -> Posix -> String
hour zone now =
    pad 2 (Time.toHour zone now) ++ ":" ++ pad 2 (Time.toMinute zone now)


pad : Int -> Int -> String
pad width number =
    String.padLeft width '0' (String.fromInt number)


monthNumber : Month -> Int
monthNumber month =
    case month of
        Jan ->
            1

        Feb ->
            2

        Mar ->
            3

        Apr ->
            4

        May ->
            5

        Jun ->
            6

        Jul ->
            7

        Aug ->
            8

        Sep ->
            9

        Oct ->
            10

        Nov ->
            11

        Dec ->
            12
