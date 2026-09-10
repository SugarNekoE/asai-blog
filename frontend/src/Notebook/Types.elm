module Notebook.Types exposing (Actions, State)

import Post exposing (Post)
import Set


type alias State a =
    { a
        | posts : List Post
        , category : String
        , selectedTags : Set.Set String
        , query : String
        , oldest : Bool
        , indexPage : Int
        , pageSize : Int
        , selectedNote : Maybe String
        , tagPickerOpen : Bool
    }


type alias Actions msg =
    { search : String -> msg
    , setTag : String -> Bool -> msg
    , toggleSort : msg
    , clearTags : msg
    , goToPage : Int -> msg
    , setPageSize : String -> msg
    , selectNote : String -> msg
    , setTagPicker : Bool -> msg
    }
