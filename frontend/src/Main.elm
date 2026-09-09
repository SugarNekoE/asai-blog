port module Main exposing (main)

import Browser
import Browser.Navigation as Navigation
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onCheck, onClick, onFocus, onInput, onMouseEnter, preventDefaultOn)
import Json.Decode as D
import Json.Encode as E
import LinkHints exposing (Hint)
import Search as SearchQuery
import Set
import Url


port setTheme : String -> Cmd msg


port setSearchOpen : Bool -> Cmd msg


port searchRequested : (() -> msg) -> Sub msg


port setKeymapOpen : Bool -> Cmd msg


port keymapRequested : (() -> msg) -> Sub msg


port scrollSearchResult : Int -> Cmd msg


port persistFilters : { tags : List String, category : String, query : String, indexPage : Int, pageSize : Int, oldest : Bool } -> Cmd msg


port scrollNotebook : () -> Cmd msg


port clockChanged : (Clock -> msg) -> Sub msg


port timingsChanged : (PageTimings -> msg) -> Sub msg


port pageCommand : (String -> msg) -> Sub msg


port setImmersiveMode : Bool -> Cmd msg


port collectLinkHints : () -> Cmd msg


port clearLinkHints : () -> Cmd msg


port followLinkHint : String -> Cmd msg


port linkHintsReady : (List Hint -> msg) -> Sub msg


port hintKey : (String -> msg) -> Sub msg


type alias PageTimings =
    { loading : Float
    , rendering : Float
    }


type alias Clock =
    { label : String
    , iso : String
    }


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


type alias Flags =
    { index : D.Value
    , clock : Clock
    , article : String
    , page : String
    , category : String
    , theme : String
    , selectedTags : List String
    , query : String
    , headings : List Heading
    , indexPage : Int
    , pageSize : Int
    , oldest : Bool
    }


type alias Model =
    { posts : List Post
    , timings : Maybe PageTimings
    , clock : Clock
    , article : String
    , page : String
    , category : String
    , theme : String
    , selectedTags : Set.Set String
    , query : String
    , headings : List Heading
    , oldest : Bool
    , indexPage : Int
    , pageSize : Int
    , menu : Bool
    , failed : Bool
    , launcherOpen : Bool
    , launcherQuery : String
    , launcherSelection : Int
    , outlineVisible : Bool
    , immersive : Bool
    , selectedNote : Maybe String
    , hintsActive : Bool
    , hints : List Hint
    , hintPrefix : String
    }


type Msg
    = Search String
    | ClockChanged Clock
    | TimingsChanged PageTimings
    | SetTag String Bool
    | NavigateCategory String
    | ToggleSort
    | ToggleTheme
    | ToggleMenu
    | OpenLauncher
    | CloseLauncher
    | OpenKeymap
    | CloseKeymap
    | LauncherQuery String
    | MoveLauncher Int
    | SelectLauncher Int
    | OpenLauncherResult
    | ClearTags
    | GoToPage Int
    | SetPageSize String
    | PageCommand String
    | SelectNote String
    | HintsReady (List Hint)
    | HintKey String


main : Program Flags Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions =
            always
                (Sub.batch
                    [ clockChanged ClockChanged
                    , timingsChanged TimingsChanged
                    , searchRequested (always OpenLauncher)
                    , keymapRequested (always OpenKeymap)
                    , pageCommand PageCommand
                    , linkHintsReady HintsReady
                    , hintKey HintKey
                    ]
                )
        }


postDecoder : D.Decoder Post
postDecoder =
    D.map8 Post
        (D.field "title" D.string)
        (D.field "description" D.string)
        (D.field "date" D.string)
        (D.field "url" D.string)
        (D.field "tags" (D.list D.string))
        (D.field "readingMinutes" D.int)
        (D.field "searchText" D.string)
        (D.field "category" D.string)


init : Flags -> ( Model, Cmd Msg )
init flags =
    let
        decoded =
            D.decodeValue
                (D.field "version" D.int
                    |> D.andThen
                        (\version ->
                            if version == 2 then
                                D.field "posts" (D.list postDecoder)

                            else
                                D.fail "Unsupported index version"
                        )
                )
                flags.index
    in
    ( { posts = Result.withDefault [] decoded
      , timings = Nothing
      , clock = flags.clock
      , article = flags.article
      , page = flags.page
      , category = flags.category
      , theme = flags.theme
      , selectedTags = Set.fromList (List.filter (not << String.isEmpty) flags.selectedTags)
      , query = flags.query
      , headings = flags.headings
      , oldest = flags.oldest
      , indexPage = flags.indexPage
      , pageSize = validPageSize flags.pageSize
      , menu = False
      , failed = Result.toMaybe decoded == Nothing
      , launcherOpen = False
      , launcherQuery = ""
      , launcherSelection = 0
      , outlineVisible = True
      , immersive = False
      , selectedNote = Nothing
      , hintsActive = False
      , hints = []
      , hintPrefix = ""
      }
    , Cmd.none
    )
        |> Tuple.mapFirst
            (\model -> { model | indexPage = clamp 1 (pageCount model) model.indexPage })


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        PageCommand command ->
            case command of
                "theme" ->
                    update ToggleTheme model

                "outline" ->
                    if model.page == "post" && not model.immersive && not (List.isEmpty model.headings) then
                        ( { model | outlineVisible = not model.outlineVisible }, Cmd.none )

                    else
                        ( model, Cmd.none )

                "immersive" ->
                    ( { model
                        | immersive = not model.immersive
                        , menu = False
                        , launcherOpen = False
                        , hintsActive = False
                        , hints = []
                        , hintPrefix = ""
                      }
                    , Cmd.batch [ setImmersiveMode (not model.immersive), clearLinkHints () ]
                    )

                "open-note" ->
                    ( model
                    , if model.page == "index" && not model.failed then
                        selectedIndexNote model
                            |> Maybe.map (.url >> Navigation.load)
                            |> Maybe.withDefault Cmd.none

                      else
                        Cmd.none
                    )

                "hints" ->
                    ( { model | hintsActive = True, hints = [], hintPrefix = "" }, collectLinkHints () )

                _ ->
                    ( model, Cmd.none )

        SelectNote url ->
            ( { model | selectedNote = Just url }, Cmd.none )

        HintsReady hints ->
            ( if model.hintsActive then
                { model | hints = hints }

              else
                model
            , Cmd.none
            )

        HintKey key ->
            if not model.hintsActive then
                ( model, Cmd.none )

            else if key == "Escape" then
                ( { model | hintsActive = False, hints = [], hintPrefix = "" }, clearLinkHints () )

            else if key == "Backspace" then
                ( { model | hintPrefix = String.dropRight 1 model.hintPrefix }, Cmd.none )

            else
                let
                    prefix =
                        model.hintPrefix ++ String.toLower key

                    match =
                        List.filter (\hint -> hint.key == prefix) model.hints |> List.head
                in
                case match of
                    Just hint ->
                        ( { model | hintsActive = False, hints = [], hintPrefix = "" }, followLinkHint hint.key )

                    Nothing ->
                        ( { model | hintPrefix = prefix }, Cmd.none )

        TimingsChanged timings ->
            ( { model | timings = Just timings }, Cmd.none )

        ClockChanged clock ->
            ( { model | clock = clock }, Cmd.none )

        Search query ->
            updateFilters { model | query = query }

        SetTag tag isSelected ->
            updateFilters
                { model
                    | selectedTags =
                        if isSelected then
                            Set.insert tag model.selectedTags

                        else
                            Set.remove tag model.selectedTags
                }

        NavigateCategory category ->
            updateFilters { model | category = category, menu = False }

        ToggleSort ->
            updateFilters { model | oldest = not model.oldest }

        GoToPage number ->
            let
                updated =
                    { model | indexPage = clamp 1 (pageCount model) number, selectedNote = Nothing }
            in
            ( updated, Cmd.batch [ persistIndex updated, scrollNotebook () ] )

        SetPageSize value ->
            let
                updated =
                    { model | pageSize = validPageSize (Maybe.withDefault 10 (String.toInt value)), indexPage = 1, selectedNote = Nothing }
            in
            ( updated, Cmd.batch [ persistIndex updated, scrollNotebook () ] )

        ToggleTheme ->
            let
                theme =
                    if model.theme == "dark" then
                        "light"

                    else
                        "dark"
            in
            ( { model | theme = theme }, setTheme theme )

        ToggleMenu ->
            ( { model | menu = not model.menu }, Cmd.none )

        OpenLauncher ->
            ( { model | launcherOpen = True, launcherQuery = "", launcherSelection = 0, menu = False }
            , setSearchOpen True
            )

        CloseLauncher ->
            ( { model | launcherOpen = False }, setSearchOpen False )

        OpenKeymap ->
            ( { model | launcherOpen = False, menu = False }, setKeymapOpen True )

        CloseKeymap ->
            ( model, setKeymapOpen False )

        LauncherQuery query ->
            ( { model | launcherQuery = query, launcherSelection = 0 }, scrollSearchResult 0 )

        MoveLauncher direction ->
            let
                count =
                    List.length (launcherResults model)

                selection =
                    if count == 0 then
                        0

                    else
                        modBy count (model.launcherSelection + direction)
            in
            ( { model | launcherSelection = selection }, scrollSearchResult selection )

        SelectLauncher selection ->
            ( { model | launcherSelection = selection }, Cmd.none )

        OpenLauncherResult ->
            ( model
            , launcherResults model
                |> List.drop model.launcherSelection
                |> List.head
                |> Maybe.map (.url >> Navigation.load)
                |> Maybe.withDefault Cmd.none
            )

        ClearTags ->
            updateFilters { model | selectedTags = Set.empty }


updateFilters : Model -> ( Model, Cmd Msg )
updateFilters model =
    let
        updated =
            { model | indexPage = 1, selectedNote = Nothing }
    in
    ( updated, persistIndex updated )


persistIndex : Model -> Cmd Msg
persistIndex model =
    persistFilters
        { tags = Set.toList model.selectedTags
        , category = model.category
        , query = model.query
        , indexPage = model.indexPage
        , pageSize = model.pageSize
        , oldest = model.oldest
        }


view : Model -> Html Msg
view model =
    div [ classList [ ( "workspace", True ), ( "is-immersive", model.immersive ) ] ]
        [ a [ class "skip-link", href "#main" ] [ text "Skip to content" ]
        , sidebar model
        , div [ class "editor" ]
            [ header [ class "topbar" ]
                [ button
                    [ class "icon-button mobile-toggle"
                    , onClick ToggleMenu
                    , attribute "aria-label" "Toggle navigation"
                    , attribute "aria-controls" "navigation"
                    , attribute "aria-expanded"
                        (if model.menu then
                            "true"

                         else
                            "false"
                        )
                    ]
                    [ text "☰" ]
                , nav [ class "breadcrumbs", attribute "aria-label" "Breadcrumb" ]
                    [ a [ class "muted", href "/" ] [ text "Asai Blog" ]
                    , span [ class "slash", attribute "aria-hidden" "true" ] [ text "/" ]
                    , if model.page == "post" && not (String.isEmpty model.category) then
                        a
                            [ class "current-category"
                            , href ("/?category=" ++ Url.percentEncode model.category)
                            , title model.category
                            ]
                            [ text model.category ]

                      else
                        span [ class "current-category" ]
                            [ text
                                (if model.page == "404" then
                                    "Page not found"

                                 else if String.isEmpty model.category then
                                    "All Notes"

                                 else
                                    model.category
                                )
                            ]
                    ]
                , div [ class "top-actions" ]
                    [ time
                        [ class "local-clock"
                        , datetime model.clock.iso
                        , attribute "aria-label" "Current local time"
                        , title "Your browser's local time"
                        ]
                        [ text model.clock.label ]
                    , button
                        [ class "icon-button"
                        , onClick ToggleTheme
                        , attribute "aria-label" "Toggle color theme"
                        , title "Toggle color theme"
                        ]
                        [ text
                            (if model.theme == "dark" then
                                "☼"

                             else
                                "◐"
                            )
                        ]
                    ]
                ]
            , if model.immersive then
                immersiveHeader

              else
                text ""
            , main_
                [ id "main"
                , tabindex -1
                , classList
                    [ ( "main-content", True )
                    , ( "reading-layout", model.page == "post" && not model.immersive && model.outlineVisible && not (List.isEmpty model.headings) )
                    ]
                ]
                [ if model.page == "index" && not model.failed then
                    indexView model

                  else
                    node "blog-content" [ property "html" (E.string model.article) ] []
                , if model.page == "post" && not model.immersive && model.outlineVisible && not (List.isEmpty model.headings) then
                    pageOutline model.headings

                  else
                    text ""
                ]
            , footer
                [ class "statusbar"
                ]
                [ span
                    [ class "page-timings"
                    , attribute "aria-label" "Page performance"
                    , title "Loading: navigation start to load event. Rendering: Elm initialization to first paint opportunity."
                    ]
                    [ text
                        (case model.timings of
                            Just timings ->
                                "loading "
                                    ++ formatMilliseconds timings.loading
                                    ++ "ms / rendered "
                                    ++ formatMilliseconds timings.rendering
                                    ++ "ms"

                            Nothing ->
                                "loading… / rendering…"
                        )
                    ]
                , a
                    [ href "https://forge.asnk.io/sugar/asai-blog"
                    , title "Asai Blog source repository"
                    ]
                    [ text "Markdown"
                    , span
                        [ class "status-divider"
                        ]
                        [ text "·"
                        ]
                    , text "Hakyll + Elm"
                    , span
                        [ class "status-divider"
                        ]
                        [ text "·"
                        ]
                    , text "UTF-8"
                    ]
                ]
            ]
        , searchLauncher model
        , keymapPanel
        , if model.hintsActive then
            LinkHints.view model.hintPrefix model.hints

          else
            text ""
        ]


immersiveHeader : Html Msg
immersiveHeader =
    header [ class "immersive-header" ]
        [ a [ class "immersive-brand", href "/" ]
            [ span [ class "brand-mark", attribute "aria-hidden" "true" ] [ text "λ" ]
            , span [] [ text "Asai Blog" ]
            ]
        , div [ class "immersive-controls" ]
            [ span [ class "immersive-label" ] [ text "Immersive Mode" ]
            , button
                [ class "immersive-exit"
                , onClick (PageCommand "immersive")
                , attribute "aria-label" "Exit immersive mode"
                , title "Exit immersive mode (Shift+I)"
                ]
                [ kbd [] [ text "Shift + I" ]
                , span [] [ text "to exit" ]
                ]
            ]
        ]


keymapPanel : Html Msg
keymapPanel =
    node "dialog"
        [ id "keymap-dialog"
        , class "search-dialog keymap-dialog"
        , attribute "aria-labelledby" "keymap-title"
        , attribute "aria-modal" "true"
        , preventDefaultOn "cancel" (D.succeed ( CloseKeymap, True ))
        , preventDefaultOn "keydown"
            (D.field "key" D.string
                |> D.andThen
                    (\key ->
                        if key == "Escape" then
                            D.succeed ( CloseKeymap, True )

                        else
                            D.fail "Other key"
                    )
            )
        , Html.Events.on "click"
            (D.at [ "target", "id" ] D.string
                |> D.andThen
                    (\target ->
                        if target == "keymap-dialog" then
                            D.succeed CloseKeymap

                        else
                            D.fail "Inside the panel"
                    )
            )
        ]
        [ div [ class "launcher-panel" ]
            [ div [ class "launcher-heading" ]
                [ h2 [ id "keymap-title" ] [ text "Keyboard shortcuts" ]
                , button
                    [ id "keymap-close"
                    , class "launcher-close"
                    , onClick CloseKeymap
                    , attribute "aria-label" "Close keyboard shortcuts"
                    ]
                    [ text "esc" ]
                ]
            , p [ class "launcher-help" ] [ text "Use page shortcuts outside text fields. Tab to a note title or hover a note to select it." ]
            , dl [ class "keymap-list" ]
                (List.map
                    (\( keys, description ) ->
                        div [ class "keymap-row" ]
                            [ dt [] [ kbd [] [ text keys ] ]
                            , dd [] [ text description ]
                            ]
                    )
                    [ ( "?", "Open keyboard shortcuts" )
                    , ( "/", "Open search" )
                    , ( "t", "Toggle theme" )
                    , ( "o", "Show or hide the article’s table of contents" )
                    , ( "Shift + I", "Toggle Immersive Mode" )
                    , ( "f", "Show letter hints for links and categories" )
                    , ( "Esc", "Close panel, cancel hints, or clear focus" )
                    , ( "Backspace", "Remove the last hint letter" )
                    , ( "↑ / ↓", "Select a search result" )
                    , ( "Enter", "Open the selected note or search result" )
                    , ( "Tab / Shift + Tab", "Move between panel controls" )
                    ]
                )
            ]
        ]


launcherMatches : Model -> List Post
launcherMatches model =
    model.posts
        |> List.filter (SearchQuery.matches model.launcherQuery)
        |> List.sortBy .date
        |> List.reverse


launcherResults : Model -> List Post
launcherResults model =
    List.take 20 (launcherMatches model)


launcherKeys : D.Decoder ( Msg, Bool )
launcherKeys =
    D.field "key" D.string
        |> D.andThen
            (\key ->
                case key of
                    "ArrowDown" ->
                        D.succeed ( MoveLauncher 1, True )

                    "ArrowUp" ->
                        D.succeed ( MoveLauncher -1, True )

                    "Enter" ->
                        D.succeed ( OpenLauncherResult, True )

                    _ ->
                        D.fail "Use the browser's normal key handling"
            )


searchLauncher : Model -> Html Msg
searchLauncher model =
    let
        results =
            launcherResults model
    in
    node "dialog"
        [ id "search-dialog"
        , class "search-dialog"
        , attribute "aria-labelledby" "search-dialog-title"
        , attribute "aria-modal" "true"
        , preventDefaultOn "cancel" (D.succeed ( CloseLauncher, True ))
        , preventDefaultOn "keydown"
            (D.field "key" D.string
                |> D.andThen
                    (\key ->
                        if key == "Escape" then
                            D.succeed ( CloseLauncher, True )

                        else
                            D.fail "Let other keys reach their normal handlers"
                    )
            )
        , Html.Events.on "click"
            (D.at [ "target", "id" ] D.string
                |> D.andThen
                    (\target ->
                        if target == "search-dialog" then
                            D.succeed CloseLauncher

                        else
                            D.fail "Inside the panel"
                    )
            )
        ]
        [ div [ class "launcher-panel" ]
            [ div [ class "launcher-heading" ]
                [ h2 [ id "search-dialog-title" ] [ text "Search notes" ]
                , button
                    [ class "launcher-close"
                    , onClick CloseLauncher
                    , attribute "aria-label" "Close search"
                    ]
                    [ text "esc" ]
                ]
            , input
                [ id "launcher-search"
                , type_ "search"
                , attribute "role" "combobox"
                , attribute "aria-label" "Search all notes"
                , attribute "aria-autocomplete" "list"
                , attribute "aria-controls" "launcher-results"
                , attribute "aria-describedby" "launcher-help"
                , attribute "aria-expanded"
                    (if model.launcherOpen then
                        "true"

                     else
                        "false"
                    )
                , attribute "aria-activedescendant"
                    (if List.isEmpty results then
                        ""

                     else
                        "search-result-" ++ String.fromInt model.launcherSelection
                    )
                , autocomplete False
                , placeholder "Search titles, descriptions, #tags or /categories…"
                , value model.launcherQuery
                , onInput LauncherQuery
                , preventDefaultOn "keydown" launcherKeys
                ]
                []
            , p [ id "launcher-help", class "launcher-help" ]
                [ text "Words search titles and descriptions. Use #tag or /category; combine them to narrow the results." ]
            , p [ class "launcher-count", attribute "role" "status" ]
                [ text
                    (if model.failed then
                        "The search index is unavailable. Reload the page to try again."

                     else
                        String.fromInt (List.length (launcherMatches model))
                            ++ " matching notes"
                            ++ (if List.length (launcherMatches model) > 20 then
                                    " · showing the first 20"

                                else
                                    ""
                               )
                    )
                ]
            , div
                [ id "launcher-results"
                , class "launcher-results"
                , attribute "role" "listbox"
                , attribute "aria-label" "Matching notes"
                ]
                (List.indexedMap (launcherResult model.launcherSelection) results)
            , if List.isEmpty results && not model.failed then
                p [ class "launcher-empty" ] [ text "No notes match. Try another keyword, #tag, or /category." ]

              else
                text ""
            , div [ class "launcher-footer" ]
                [ text "↑ ↓ to navigate · enter to open · esc to close" ]
            ]
        ]


launcherResult : Int -> Int -> Post -> Html Msg
launcherResult active index post =
    a
        [ id ("search-result-" ++ String.fromInt index)
        , classList [ ( "launcher-result", True ), ( "is-selected", active == index ) ]
        , href post.url
        , attribute "role" "option"
        , attribute "aria-selected"
            (if active == index then
                "true"

             else
                "false"
            )
        , tabindex -1
        , onMouseEnter (SelectLauncher index)
        ]
        [ span [ class "launcher-result-title" ] [ text post.title ]
        , span [ class "launcher-result-description" ] [ text post.description ]
        , span [ class "launcher-result-meta" ]
            ([ text ("/" ++ post.category ++ " · ") ]
                ++ List.intersperse (text " ")
                    (List.map
                        (\tag ->
                            span [ class "launcher-tag", attribute "data-tag" tag ] [ text ("#" ++ tag) ]
                        )
                        post.tags
                    )
            )
        ]


formatMilliseconds : Float -> String
formatMilliseconds milliseconds =
    milliseconds
        |> Basics.max 0
        |> round
        |> String.fromInt


sidebar : Model -> Html Msg
sidebar model =
    let
        categories =
            model.posts |> List.map .category |> Set.fromList |> Set.toList
    in
    aside [ classList [ ( "sidebar", True ), ( "is-open", model.menu ) ], id "navigation" ]
        [ a
            [ class "brand"
            , href "/"
            ]
            [ span
                [ class "brand-mark"
                ]
                [ text "λ"
                ]
            , span
                []
                [ text "Asai Blog"
                , small
                    []
                    [ text "FIELD NOTES"
                    ]
                ]
            ]
        , button
            [ class "search-launch"
            , onClick OpenLauncher
            , attribute "aria-haspopup" "dialog"
            , attribute "aria-controls" "search-dialog"
            ]
            [ span [ class "symbol search-icon", attribute "aria-hidden" "true" ] [ text "⌕" ]
            , span [] [ text "Search notes" ]
            , kbd [] [ text "/" ]
            ]
        , div [ class "sidebar-label" ] [ text "EXPLORER", span [] [ text "···" ] ]
        , nav [ attribute "aria-label" "Main navigation" ]
            [ a
                [ href "/"
                , classList
                    [ ( "nav-item"
                      , True
                      )
                    , ( "selected"
                      , model.page == "index" && String.isEmpty model.category
                      )
                    ]
                ]
                [ span
                    [ class "nav-icon"
                    ]
                    [ text "▤"
                    ]
                , text "All Notes"
                , span
                    [ class "count"
                    ]
                    [ text (String.fromInt (List.length model.posts))
                    ]
                ]
            , a
                [ href "/feed.xml"
                , class "nav-item"
                ]
                [ span
                    [ class "nav-icon"
                    ]
                    [ text "◉"
                    ]
                , text "RSS feed"
                , span
                    [ class "count symbol"
                    ]
                    [ text "↗"
                    ]
                ]
            ]
        , div [ class "sidebar-label category-label" ] [ text "CATEGORIES" ]
        , nav [ class "category-list", attribute "aria-label" "Categories" ]
            (List.map (categoryView model) categories)
        , div
            [ class "sidebar-bottom"
            ]
            [ div [ class "sidebar-links" ]
                [ a [ href "https://sne.moe" ] [ text "sne.moe ↗" ]
                , p []
                    [ a
                        [ href "https://creativecommons.org/licenses/by-sa/4.0/"
                        , rel "license"
                        ]
                        [ text "CC-BY-SA 4.0" ]
                    ]
                ]
            , button
                [ class "keymap-trigger"
                , onClick OpenKeymap
                , attribute "aria-label" "Keyboard shortcuts"
                , attribute "aria-haspopup" "dialog"
                , title "Keyboard shortcuts (?)"
                ]
                [ text "?" ]
            ]
        ]


pageOutline : List Heading -> Html Msg
pageOutline headings =
    aside
        [ class "page-outline"
        , attribute "aria-labelledby" "page-outline-title"
        ]
        [ h2 [ id "page-outline-title" ] [ text "ON THIS PAGE" ]
        , nav [ attribute "aria-label" "Table of contents" ]
            (List.map
                (\heading ->
                    a [ href ("#" ++ heading.id) ] [ text heading.label ]
                )
                headings
            )
        ]


categoryView : Model -> String -> Html Msg
categoryView model category =
    let
        children =
            [ span [ class "category-icon", attribute "aria-hidden" "true" ] [ text "▱" ]
            , span [ class "category-name" ] [ text category ]
            , span [ class "count" ]
                [ text
                    (model.posts
                        |> List.filter (\post -> post.category == category)
                        |> List.length
                        |> String.fromInt
                    )
                ]
            ]

        attributes =
            [ classList
                [ ( "category-item", True )
                , ( "active", model.category == category )
                ]
            ]
    in
    if model.page == "index" then
        button
            (attributes
                ++ [ onClick (NavigateCategory category)
                   , attribute "data-link-hint" category
                   , attribute "aria-pressed"
                        (if model.category == category then
                            "true"

                         else
                            "false"
                        )
                   ]
            )
            children

    else
        a
            (attributes ++ [ href ("/?category=" ++ Url.percentEncode category) ])
            children


tagFilters : Model -> Html Msg
tagFilters model =
    let
        availableTags =
            model.posts
                |> List.concatMap .tags
                |> Set.fromList
                |> Set.toList
    in
    div [ class "index-filters" ]
        [ details [ class "tag-picker" ]
            [ summary []
                [ text "Tags"
                , span [ class "tag-selection-count" ]
                    [ text (String.fromInt (Set.size model.selectedTags)) ]
                ]
            , div
                [ class "tag-options"
                , attribute "role" "group"
                , attribute "aria-label" "Available tags"
                ]
                (p [ class "filter-mode" ] [ text "Match all selected tags" ]
                    :: List.map
                        (\tag ->
                            label [ class "tag-option", attribute "data-tag" tag ]
                                [ input
                                    [ type_ "checkbox"
                                    , checked (Set.member tag model.selectedTags)
                                    , onCheck (SetTag tag)
                                    , attribute "aria-label" ("Select tag " ++ tag)
                                    ]
                                    []
                                , span [] [ text ("# " ++ tag) ]
                                ]
                        )
                        availableTags
                )
            ]
        , div
            [ class "selected-tags"
            , attribute "role" "group"
            , attribute "aria-label" "Selected tags"
            ]
            (model.selectedTags
                |> Set.toList
                |> List.map
                    (\tag ->
                        button
                            [ class "selected-tag"
                            , attribute "data-tag" tag
                            , onClick (SetTag tag False)
                            , attribute "aria-label" ("Remove tag " ++ tag)
                            ]
                            [ text ("# " ++ tag)
                            , span [ attribute "aria-hidden" "true" ] [ text "×" ]
                            ]
                    )
            )
        , if Set.isEmpty model.selectedTags then
            text ""

          else
            button [ class "clear-filters", onClick ClearTags ] [ text "Clear filters" ]
        ]


indexPosts : Model -> List Post
indexPosts model =
    let
        categoryPosts =
            List.filter
                (\post -> String.isEmpty model.category || post.category == model.category)
                model.posts

        matches post =
            List.all (\tag -> List.member tag post.tags) (Set.toList model.selectedTags)
                && List.all
                    (\word ->
                        String.contains word
                            (String.toLower
                                (post.title
                                    ++ " "
                                    ++ post.description
                                    ++ " "
                                    ++ String.join " " post.tags
                                    ++ " "
                                    ++ post.searchText
                                )
                            )
                    )
                    (String.words (String.toLower model.query))

        filtered =
            List.filter matches categoryPosts |> List.sortBy .date
    in
    if model.oldest then
        filtered

    else
        List.reverse filtered


validPageSize : Int -> Int
validPageSize size =
    if List.member size [ 10, 30, 50, 100 ] then
        size

    else
        10


visibleIndexNotes : Model -> List Post
visibleIndexNotes model =
    indexPosts model
        |> List.drop ((model.indexPage - 1) * model.pageSize)
        |> List.take model.pageSize


selectedIndexNote : Model -> Maybe Post
selectedIndexNote model =
    let
        notes =
            visibleIndexNotes model
    in
    case List.filter (\post -> Just post.url == model.selectedNote) notes |> List.head of
        Just post ->
            Just post

        Nothing ->
            List.head notes


pageCount : Model -> Int
pageCount model =
    Basics.max 1 ((List.length (indexPosts model) + model.pageSize - 1) // model.pageSize)


paginationView : Model -> Int -> Html Msg
paginationView model total =
    let
        count =
            pageCount model

        numbers =
            [ 1, model.indexPage - 1, model.indexPage, model.indexPage + 1, count ]
                |> List.filter (\number -> number >= 1 && number <= count)
                |> Set.fromList
                |> Set.toList

        first =
            (model.indexPage - 1) * model.pageSize + 1
    in
    div [ class "pagination" ]
        [ div [ class "pagination-settings" ]
            [ label [ for "notes-per-page" ] [ text "Notes per page" ]
            , select [ id "notes-per-page", onInput SetPageSize ]
                (List.map
                    (\size ->
                        option
                            [ attribute "value" (String.fromInt size)
                            , selected (size == model.pageSize)
                            ]
                            [ text (String.fromInt size) ]
                    )
                    [ 10, 30, 50, 100 ]
                )
            ]
        , span [ class "pagination-summary", attribute "aria-live" "polite" ]
            [ text
                (if total == 0 then
                    "0 notes"

                 else
                    String.fromInt first
                        ++ "–"
                        ++ String.fromInt (Basics.min total (first + model.pageSize - 1))
                        ++ " of "
                        ++ String.fromInt total
                        ++ " notes"
                )
            ]
        , nav [ class "pagination-controls", attribute "aria-label" "Notes pagination" ]
            [ button
                [ onClick (GoToPage (model.indexPage - 1))
                , disabled (model.indexPage <= 1)
                ]
                [ text "Previous" ]
            , div [ class "pagination-pages" ]
                (List.indexedMap
                    (\index number ->
                        let
                            previous =
                                List.drop (index - 1) numbers |> List.head |> Maybe.withDefault 0
                        in
                        span [ class "pagination-step" ]
                            [ if index > 0 && number > previous + 1 then
                                span [ class "pagination-gap", attribute "aria-hidden" "true" ] [ text "…" ]

                              else
                                text ""
                            , button
                                [ onClick (GoToPage number)
                                , attribute "aria-label" ("Go to page " ++ String.fromInt number)
                                , attribute "aria-current"
                                    (if model.indexPage == number then
                                        "page"

                                     else
                                        "false"
                                    )
                                ]
                                [ text (String.fromInt number) ]
                            ]
                    )
                    numbers
                )
            , button
                [ onClick (GoToPage (model.indexPage + 1))
                , disabled (model.indexPage >= count)
                ]
                [ text "Next" ]
            ]
        ]


indexView : Model -> Html Msg
indexView model =
    let
        posts =
            indexPosts model

        offset =
            (model.indexPage - 1) * model.pageSize

        visiblePosts =
            visibleIndexNotes model
    in
    div []
        [ header [ class "intro" ]
            [ p
                [ class "eyebrow"
                ]
                [ span
                    [ class "accent"
                    ]
                    [ text "~/"
                    ]
                , text " A PERSONAL KNOWLEDGE BASE"
                ]
            , h1
                []
                [ text "Thinking in "
                , em
                    []
                    [ text "systems."
                    ]
                , br
                    []
                    []
                , text "Writing in plain text."
                ]
            , p
                [ class "intro-description"
                ]
                [ text "Field notes on code, tools, and the things in between."
                , br
                    []
                    []
                , text "A little less noise. A little more understanding."
                ]
            , div
                [ class "intro-meta"
                ]
                [ span
                    []
                    [ span
                        [ class "dot"
                        ]
                        []
                    , text "learning in public"
                    ]
                , span
                    []
                    [ text "//"
                    ]
                , span
                    []
                    [ text (String.fromInt (List.length model.posts) ++ " notes and counting")
                    ]
                ]
            ]
        , div
            [ class "collection-header"
            ]
            [ h2
                [ id "notebook-heading", tabindex -1 ]
                [ text "The notebook"
                , span
                    [ class "muted"
                    ]
                    [ text " /"
                    ]
                ]
            , span
                [ class "eyebrow"
                ]
                [ text "IDEAS, COMMITTED."
                ]
            ]
        , div [ class "filterbar" ]
            [ tagFilters model
            , button [ class "sort-button", onClick ToggleSort ]
                [ span [ class "symbol", attribute "aria-hidden" "true" ]
                    [ text
                        (if model.oldest then
                            "↑"

                         else
                            "↓"
                        )
                    ]
                , text
                    (if model.oldest then
                        "Oldest first"

                     else
                        "Newest first"
                    )
                ]
            ]
        , div
            [ class "search-field"
            ]
            [ span
                [ class "symbol search-icon"
                , attribute "aria-hidden" "true"
                ]
                [ text "⌕"
                ]
            , input
                [ id "note-search"
                , type_ "search"
                , placeholder "Find something..."
                , attribute "aria-label" "Search notes"
                , value model.query
                , onInput Search
                ]
                []
            , kbd
                []
                [ text "/"
                ]
            ]
        , p [ class "result-count", attribute "role" "status" ]
            [ text
                (String.fromInt (List.length posts)
                    ++ (if List.length posts == 1 then
                            " note"

                        else
                            " notes"
                       )
                    ++ (if String.isEmpty model.query && Set.isEmpty model.selectedTags then
                            if String.isEmpty model.category then
                                " in the notebook"

                            else
                                " in " ++ model.category

                        else
                            " found"
                       )
                )
            ]
        , if List.isEmpty posts then
            div
                [ class "empty-state"
                ]
                [ span
                    [ class "accent"
                    ]
                    [ text "∅"
                    ]
                , h3
                    []
                    [ text "No notes on this path. Yet."
                    ]
                , p
                    []
                    [ text "Try another keyword, remove a tag, or choose a different category."
                    ]
                , if Set.isEmpty model.selectedTags then
                    text ""

                  else
                    button
                        [ class "reset-button", onClick ClearTags ]
                        [ text "Clear filters →" ]
                , if String.isEmpty model.query then
                    text ""

                  else
                    button
                        [ class "reset-button", onClick (Search "") ]
                        [ text "Clear search" ]
                ]

          else
            div [ class "post-list" ]
                (List.indexedMap (\index post -> postView model.selectedTags (Maybe.map .url (selectedIndexNote model)) (offset + index) post) visiblePosts)
        , paginationView model (List.length posts)
        , if not (List.isEmpty posts) && model.indexPage == pageCount model then
            div [ class "notebook-end" ] [ text "You've reached the edge of the notebook." ]

          else
            text ""
        ]


postView : Set.Set String -> Maybe String -> Int -> Post -> Html Msg
postView selectedTags selectedNote index post =
    article
        [ classList [ ( "post-row", True ), ( "is-selected", selectedNote == Just post.url ) ]
        , onMouseEnter (SelectNote post.url)
        ]
        [ div
            [ class "post-date"
            ]
            [ time
                [ datetime post.date
                ]
                [ text (String.dropLeft 5 post.date |> String.replace "-" ".")
                ]
            , small
                []
                [ text (String.left 4 post.date)
                ]
            ]
        , div [ class "post-details" ]
            [ div
                [ class "post-kicker"
                ]
                [ text ("NOTE " ++ String.padLeft 2 '0' (String.fromInt (index + 1)))
                , span [ class "post-category" ] [ text post.category ]
                , span
                    [ class "read-time"
                    ]
                    [ text (String.fromInt post.readingMinutes ++ " min read")
                    ]
                ]
            , h3
                []
                [ a
                    [ href post.url
                    , onFocus (SelectNote post.url)
                    ]
                    [ text post.title
                    , span
                        [ class "post-arrow"
                        ]
                        [ text "↗"
                        ]
                    ]
                ]
            , p [] [ text post.description ]
            , div
                [ class "tags"
                ]
                (List.map
                    (\tag ->
                        button
                            [ class "tag"
                            , attribute "data-tag" tag
                            , onClick (SetTag tag True)
                            , attribute "aria-label" ("Filter by tag " ++ tag)
                            , attribute "aria-pressed"
                                (if Set.member tag selectedTags then
                                    "true"

                                 else
                                    "false"
                                )
                            ]
                            [ text ("# " ++ tag)
                            ]
                    )
                    post.tags
                )
            ]
        ]
