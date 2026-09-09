module Post exposing (Heading, Post, indexDecoder)

import Json.Decode as D


type alias Post =
    { title : String
    , description : String
    , date : String
    , url : String
    , tags : List String
    , readingMinutes : Int
    , searchText : String
    , category : String
    }


type alias Heading =
    { id : String
    , label : String
    }


decoder : D.Decoder Post
decoder =
    D.map8 Post
        (D.field "title" D.string)
        (D.field "description" D.string)
        (D.field "date" D.string)
        (D.field "url" D.string)
        (D.field "tags" (D.list D.string))
        (D.field "readingMinutes" D.int)
        (D.field "searchText" D.string)
        (D.field "category" D.string)


indexDecoder : D.Decoder (List Post)
indexDecoder =
    D.field "version" D.int
        |> D.andThen
            (\version ->
                if version == 2 then
                    D.field "posts" (D.list decoder)

                else
                    D.fail "Unsupported index version"
            )
