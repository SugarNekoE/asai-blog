module IndexQuery exposing (State, encode, parse, validPageSize)

import Url
import Url.Builder


type alias State =
    { tags : List String
    , category : String
    , query : String
    , indexPage : Int
    , pageSize : Int
    , oldest : Bool
    , extra : List ( String, String )
    }


parse : String -> State
parse search =
    let
        parameters =
            search
                |> String.dropLeft
                    (if String.startsWith "?" search then
                        1

                     else
                        0
                    )
                |> String.split "&"
                |> List.filter (not << String.isEmpty)
                |> List.map parameter

        values key =
            parameters |> List.filter (Tuple.first >> (==) key) |> List.map Tuple.second

        first key =
            values key |> List.head |> Maybe.withDefault ""

        page =
            first "page" |> String.toInt |> Maybe.withDefault 1
    in
    { tags = values "tag" |> List.filter (not << String.isEmpty)
    , category = first "category"
    , query = first "q"
    , indexPage =
        if page > 0 && page <= 2147483647 then
            page

        else
            1
    , pageSize = first "perPage" |> String.toInt |> Maybe.withDefault 10 |> validPageSize
    , oldest = first "sort" == "oldest"
    , extra = List.filter (Tuple.first >> managed >> not) parameters
    }


parameter : String -> ( String, String )
parameter segment =
    case String.split "=" segment of
        key :: values ->
            ( decode key, decode (String.join "=" values) )

        [] ->
            ( "", "" )


decode : String -> String
decode value =
    String.replace "+" " " value |> Url.percentDecode |> Maybe.withDefault value


managed : String -> Bool
managed key =
    List.member key [ "tag", "category", "q", "page", "perPage", "sort" ]


validPageSize : Int -> Int
validPageSize size =
    if List.member size [ 10, 30, 50, 100 ] then
        size

    else
        10


encode : State -> String
encode state =
    let
        parameters =
            [ ( "category", state.category )
            , ( "q", state.query )
            , ( "page"
              , if state.indexPage > 1 then
                    String.fromInt state.indexPage

                else
                    ""
              )
            , ( "perPage"
              , if state.pageSize /= 10 then
                    String.fromInt state.pageSize

                else
                    ""
              )
            , ( "sort"
              , if state.oldest then
                    "oldest"

                else
                    ""
              )
            ]
                |> List.filter (Tuple.second >> String.isEmpty >> not)
    in
    state.extra
        ++ List.map (Tuple.pair "tag") state.tags
        ++ parameters
        |> List.map (\( key, value ) -> Url.Builder.string key value)
        |> Url.Builder.toQuery
