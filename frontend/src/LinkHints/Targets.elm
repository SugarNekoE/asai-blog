module LinkHints.Targets exposing (Activation, Candidate, Probe, Snapshot, candidates, visible)

import Set


type alias Rect =
    { left : Float, right : Float, top : Float, bottom : Float }


type alias Target =
    { id : Int
    , hint : String
    , ariaLabel : String
    , text : String
    , href : String
    , disabled : Bool
    , ariaDisabled : String
    , inert : Bool
    , visibility : String
    , opacity : Float
    , rects : List Rect
    }


type alias Snapshot =
    { width : Float, height : Float, targets : List Target }


type alias Activation =
    { id : Int, hitX : Float, hitY : Float }


type alias Candidate =
    { id : Int
    , label : String
    , x : Float
    , y : Float
    , hitX : Float
    , hitY : Float
    }


type alias Probe =
    { candidate : Candidate, hit : Bool }


candidates : Snapshot -> List Candidate
candidates snapshot =
    snapshot.targets
        |> List.filter
            (\target ->
                not target.disabled
                    && target.ariaDisabled
                    /= "true"
                    && not target.inert
                    && target.visibility
                    == "visible"
                    && target.opacity
                    > 0
            )
        |> List.concatMap
            (\target -> List.filterMap (place snapshot target) target.rects)


place : Snapshot -> Target -> Rect -> Maybe Candidate
place snapshot target rect =
    let
        left =
            max 0 rect.left

        right =
            min snapshot.width rect.right

        top =
            max 0 rect.top

        bottom =
            min snapshot.height rect.bottom

        label =
            [ target.hint, target.ariaLabel, String.trim target.text, target.href ]
                |> List.filter (not << String.isEmpty)
                |> List.head
                |> Maybe.withDefault ""
    in
    if right <= left || bottom <= top then
        Nothing

    else
        Just
            { id = target.id
            , label = label
            , x = max 4 (min (snapshot.width - 40) rect.left)
            , y = max 4 (min (snapshot.height - 24) rect.top)
            , hitX = (left + right) / 2
            , hitY = (top + bottom) / 2
            }


visible : List Probe -> List Candidate
visible probes =
    probes
        |> List.foldl
            (\probe ( seen, selected ) ->
                if probe.hit && not (Set.member probe.candidate.id seen) then
                    ( Set.insert probe.candidate.id seen, probe.candidate :: selected )

                else
                    ( seen, selected )
            )
            ( Set.empty, [] )
        |> Tuple.second
        |> List.reverse
