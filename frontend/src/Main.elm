module Main exposing (main)

import Browser
import Browser.Events
import Browser.Navigation as Navigation
import BrowserClock as Clock exposing (Clock)
import BrowserPorts exposing (..)
import Html.Styled as Html exposing (Html, node, text)
import Html.Styled.Attributes exposing (property)
import IndexQuery
import Json.Encode as E
import Keyboard
import Keymap
import Layout exposing (PageTimings)
import LinkHints exposing (Hint)
import LinkHints.Targets as Targets
import Notebook
import Notebook.Filters as Filters
import Notebook.Query as NotebookQuery
import Panels
import Post exposing (Heading, Post)
import SearchLauncher
import Set
import Task


type alias Flags =
    { posts : List Post
    , clock : Clock.Sample
    , article : String
    , page : String
    , category : String
    , theme : String
    , search : String
    , headings : List Heading
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
    , extraQuery : List ( String, String )
    , headings : List Heading
    , oldest : Bool
    , indexPage : Int
    , pageSize : Int
    , menu : Bool
    , panel : Panels.Panel
    , tagPickerOpen : Bool
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
    | ClockTick Clock
    | RefreshClock
    | BrowserReady
    | KeyboardPressed String
    | TimingsChanged PageTimings
    | SetTag String Bool
    | SetTagPicker Bool
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
    | HintsCollected Targets.Snapshot
    | HintsReady (List Targets.Probe)
    | HintKey String


main : Program Flags Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = view >> Html.toUnstyled
        , subscriptions =
            \model ->
                Sub.batch
                    [ clockRefreshRequested (always RefreshClock)
                    , timingsChanged TimingsChanged
                    , browserReady (always BrowserReady)
                    , keyboardPressed KeyboardPressed
                    , linkHintsReady HintsReady
                    , linkTargetsCollected HintsCollected
                    , if model.hintsActive then
                        Sub.batch
                            [ linkTargetsChanged (always (HintKey "Escape"))
                            , Browser.Events.onResize (\_ _ -> HintKey "Escape")
                            ]

                      else
                        Sub.none
                    , if model.tagPickerOpen then
                        Browser.Events.onClick (Filters.outsideClick (SetTagPicker False))

                      else
                        Sub.none
                    ]
        }


init : Flags -> ( Model, Cmd Msg )
init flags =
    let
        queryState =
            IndexQuery.parse flags.search
    in
    ( { posts = flags.posts
      , timings = Nothing
      , clock = Clock.fromBrowser flags.clock
      , article = flags.article
      , page = flags.page
      , category =
            if flags.page == "index" then
                queryState.category

            else
                flags.category
      , theme = flags.theme
      , selectedTags = Set.fromList queryState.tags
      , query = queryState.query
      , extraQuery = queryState.extra
      , headings = flags.headings
      , oldest = queryState.oldest
      , indexPage = queryState.indexPage
      , pageSize = queryState.pageSize
      , menu = False
      , panel = Panels.Closed
      , tagPickerOpen = False
      , launcherQuery = ""
      , launcherSelection = 0
      , outlineVisible = True
      , immersive = False
      , selectedNote = Nothing
      , hintsActive = False
      , hints = []
      , hintPrefix = ""
      }
    , Clock.nextTick ClockTick
    )
        |> Tuple.mapFirst
            (\model -> { model | indexPage = clamp 1 (NotebookQuery.pageCount model) model.indexPage })


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        ( next, command ) =
            updateModel msg model

        sendKeys =
            case msg of
                BrowserReady ->
                    True

                _ ->
                    Keyboard.context model /= Keyboard.context next
    in
    ( next
    , Cmd.batch
        [ command
        , if sendKeys then
            setKeyboardKeys (Keyboard.keys next)

          else
            Cmd.none
        ]
    )


updateModel : Msg -> Model -> ( Model, Cmd Msg )
updateModel msg model =
    case msg of
        BrowserReady ->
            if List.any (Tuple.first >> (==) "search") model.extraQuery then
                updateModel OpenLauncher model

            else
                ( model, Cmd.none )

        KeyboardPressed key ->
            case Keyboard.action model key of
                Keyboard.Theme ->
                    updateModel ToggleTheme model

                Keyboard.Outline ->
                    updateModel (PageCommand "outline") model

                Keyboard.Immersive ->
                    updateModel (PageCommand "immersive") model

                Keyboard.Hints ->
                    updateModel (PageCommand "hints") model

                Keyboard.OpenNote ->
                    updateModel (PageCommand "open-note") model

                Keyboard.Search ->
                    updateModel OpenLauncher model

                Keyboard.Keymap ->
                    updateModel OpenKeymap model

                Keyboard.ClearFocus ->
                    ( model, clearFocus () )

                Keyboard.HintInput input ->
                    updateModel (HintKey input) model

                Keyboard.None ->
                    ( model, Cmd.none )

        PageCommand command ->
            case command of
                "theme" ->
                    updateModel ToggleTheme model

                "outline" ->
                    if model.page == "post" && not model.immersive && not (List.isEmpty model.headings) then
                        ( { model | outlineVisible = not model.outlineVisible }, Cmd.none )

                    else
                        ( model, Cmd.none )

                "immersive" ->
                    if model.page == "post" then
                        ( { model
                            | immersive = not model.immersive
                            , menu = False
                            , panel = Panels.Closed
                            , tagPickerOpen = False
                            , hintsActive = False
                            , hints = []
                            , hintPrefix = ""
                          }
                        , Cmd.batch [ setPanel (Panels.target Panels.Closed), positionPage Panels.reading, clearLinkHints () ]
                        )

                    else
                        ( model, Cmd.none )

                "open-note" ->
                    ( model
                    , if model.page == "index" then
                        NotebookQuery.selectedIndexNote model
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

        HintsCollected snapshot ->
            ( model
            , if model.hintsActive then
                probeLinkTargets (Targets.candidates snapshot)

              else
                Cmd.none
            )

        HintsReady probes ->
            ( if model.hintsActive then
                { model | hints = LinkHints.assign (Targets.visible probes) }

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
                        ( { model | hintsActive = False, hints = [], hintPrefix = "" }
                        , followLinkHint { id = hint.id, hitX = hint.hitX, hitY = hint.hitY }
                        )

                    Nothing ->
                        ( { model | hintPrefix = prefix }, Cmd.none )

        TimingsChanged timings ->
            ( { model | timings = Just timings }, Cmd.none )

        ClockChanged clock ->
            ( { model | clock = clock }, Cmd.none )

        ClockTick clock ->
            ( { model | clock = clock }, Clock.nextTick ClockTick )

        RefreshClock ->
            ( model, Task.perform ClockChanged Clock.read )

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

        SetTagPicker isOpen ->
            ( { model | tagPickerOpen = isOpen }, Cmd.none )

        NavigateCategory category ->
            updateFilters { model | category = category, menu = False }

        ToggleSort ->
            updateFilters { model | oldest = not model.oldest }

        GoToPage number ->
            let
                updated =
                    { model | indexPage = clamp 1 (NotebookQuery.pageCount model) number, selectedNote = Nothing }
            in
            ( updated, Cmd.batch [ persistIndex updated, positionPage Panels.notebook ] )

        SetPageSize value ->
            let
                updated =
                    { model | pageSize = IndexQuery.validPageSize (Maybe.withDefault 10 (String.toInt value)), indexPage = 1, selectedNote = Nothing }
            in
            ( updated, Cmd.batch [ persistIndex updated, positionPage Panels.notebook ] )

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
            ( { model | panel = Panels.Search, launcherQuery = "", launcherSelection = 0, menu = False, tagPickerOpen = False }
            , setPanel (Panels.target Panels.Search)
            )

        CloseLauncher ->
            closePanel Panels.Search model

        OpenKeymap ->
            ( { model | panel = Panels.Keymap, menu = False, tagPickerOpen = False }, setPanel (Panels.target Panels.Keymap) )

        CloseKeymap ->
            closePanel Panels.Keymap model

        LauncherQuery query ->
            ( { model | launcherQuery = query, launcherSelection = 0 }, positionPage (Panels.searchResult 0) )

        MoveLauncher direction ->
            let
                count =
                    List.length (SearchLauncher.results model)

                selection =
                    if count == 0 then
                        0

                    else
                        modBy count (model.launcherSelection + direction)
            in
            ( { model | launcherSelection = selection }, positionPage (Panels.searchResult selection) )

        SelectLauncher selection ->
            ( { model | launcherSelection = selection }, Cmd.none )

        OpenLauncherResult ->
            ( model
            , SearchLauncher.results model
                |> List.drop model.launcherSelection
                |> List.head
                |> Maybe.map (.url >> Navigation.load)
                |> Maybe.withDefault Cmd.none
            )

        ClearTags ->
            updateFilters { model | selectedTags = Set.empty }


closePanel : Panels.Panel -> Model -> ( Model, Cmd Msg )
closePanel panel model =
    if model.panel == panel then
        ( { model | panel = Panels.Closed }, setPanel (Panels.target Panels.Closed) )

    else
        ( model, Cmd.none )


updateFilters : Model -> ( Model, Cmd Msg )
updateFilters model =
    let
        updated =
            { model | indexPage = 1, selectedNote = Nothing }
    in
    ( updated, persistIndex updated )


persistIndex : Model -> Cmd Msg
persistIndex model =
    if model.page == "index" then
        IndexQuery.encode
            { tags = Set.toList model.selectedTags
            , category = model.category
            , query = model.query
            , indexPage = model.indexPage
            , pageSize = model.pageSize
            , oldest = model.oldest
            , extra = model.extraQuery
            }
            |> replaceQuery

    else
        Cmd.none


view : Model -> Html Msg
view model =
    Layout.view
        { toggleMenu = ToggleMenu
        , toggleTheme = ToggleTheme
        , openSearch = OpenLauncher
        , openKeymap = OpenKeymap
        , navigateCategory = NavigateCategory
        , toggleImmersive = PageCommand "immersive"
        }
        model
        (if model.page == "index" then
            Notebook.view
                { search = Search
                , setTag = SetTag
                , toggleSort = ToggleSort
                , clearTags = ClearTags
                , goToPage = GoToPage
                , setPageSize = SetPageSize
                , selectNote = SelectNote
                , setTagPicker = SetTagPicker
                }
                model

         else
            node "blog-content" [ property "html" (E.string model.article) ] []
        )
        [ SearchLauncher.view
            { close = CloseLauncher
            , query = LauncherQuery
            , move = MoveLauncher
            , select = SelectLauncher
            , open = OpenLauncherResult
            }
            model
        , Keymap.view CloseKeymap
        , if model.hintsActive then
            LinkHints.view model.hintPrefix model.hints

          else
            text ""
        ]
