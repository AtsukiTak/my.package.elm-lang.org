module Page.Docs exposing (Model, Msg, Focus(..), init, update, view)

import Browser.Dom as Dom
import Elm.Docs as Docs
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Lazy exposing (..)
import Http
import Url.Builder as Url
import Task

import Page.Docs.Block as Block
import Page.Problem as Problem
import Session
import Skeleton
import Utils.Markdown as Markdown
import Href



{- *************
   Model
   ************* -}


type alias Model =
  { session : Session.Data
  , author : String
  , project : String
  , focus : Focus
  , query : String
  , readme : Status String
  , docs : Status (List Docs.Module )
  }


type Focus
  = Readme
  | Module String (Maybe String)


type Status a
  = Failure
  | Loading
  | Success a


type DocsError
  = NotFound
  | FoundButMissingModule



{- ************
   Init
   ************ -}


init : Session.Data -> String -> String -> Focus -> ( Model, Cmd Msg )
init session author project focus =
    getInfo <|
      Model session author project focus "" Loading Loading


getInfo : Model -> ( Model, Cmd Msg )
getInfo model =
  let
    author = model.author
    project = model.project
    maybeInfo =
      Maybe.map2 Tuple.pair
        (Session.getReadme model.session author project)
        (Session.getDocs model.session author project)
  in
  case maybeInfo of
    Nothing ->
      ( model
      , Cmd.batch
        [ Http.send GotReadme (Session.fetchReadme author project)
        , Http.send GotDocs (Session.fetchDocs author project)
        ]
      )

    Just (readme, docs) ->
      ( { model
            | readme = Success readme
            , docs = Success docs
        }
      , scrollIfNeeded model.focus
      )


scrollIfNeeded : Focus -> Cmd Msg
scrollIfNeeded focus =
  case focus of
    Module _ (Just tag) ->
      Task.attempt ScrollAttempted (
        Dom.getElement tag
          |> Task.andThen (\info -> Dom.setViewport 0 info.element.y)
      )

    _ ->
      Cmd.none



{- *************
   Update
   ************* -}


type Msg
  = QueryChanged String
  | ScrollAttempted (Result Dom.Error ())
  | GotReadme (Result Http.Error String)
  | GotDocs (Result Http.Error (List Docs.Module))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  case msg of
    QueryChanged query ->
      ( { model | query = query }
      , Cmd.none
      )

    ScrollAttempted _ ->
      ( model
      , Cmd.none
      )

    GotReadme result ->
      case result of
        Err _ ->
          ( { model | readme = Failure }
          , Cmd.none
          )

        Ok readme ->
          ( { model
                | readme = Success readme
                , session = Session.addReadme model.author model.project readme model.session
            }
          , Cmd.none
          )

    GotDocs result ->
      case result of
        Err _ ->
          ( { model | docs = Failure }
          , Cmd.none
          )

        Ok docs ->
          ( { model
                | docs = Success docs
                , session = Session.addDocs model.author model.project docs model.session
            }
          , scrollIfNeeded model.focus
          )



{- *************
   View
   ************* -}


view : Model -> Skeleton.Details Msg
view model =
  { title = toTitle model
  , header = toHeader model
  , attrs = []
  , kids =
      [ viewContent model
      , viewSidebar model
      ]
  }



-- TITLE


toTitle : Model -> String
toTitle model =
  case model.focus of
    Readme ->
      model.project

    Module name _ ->
      name ++ "-" ++ model.project



-- TO HEADER


toHeader : Model -> List Skeleton.Segment
toHeader model =
  [ Skeleton.authorSegment model.author
  , Skeleton.projectSegment model.author model.project
  ]
  ++
    case model.focus of
      Readme ->
        []

      Module name _ ->
        [ Skeleton.moduleSegment model.author model.project name
        ]



-- View Content


viewContent : Model -> Html msg
viewContent model =
  case model.focus of
    Readme ->
      lazy viewReadme model.readme

    Module name tag ->
      lazy4 viewModule model.author model.project name model.docs


viewReadme : Status String -> Html msg
viewReadme status =
  case status of
    Success readme ->
      div [ class "block-list" ] [ Markdown.block readme ]

    Loading ->
      div [ class "block-list" ] [ text "" ]

    Failure ->
      div
        (class "block-list" :: Problem.styles)
        (Problem.offline "README.md")


viewModule : String -> String -> String -> Status (List Docs.Module) -> Html msg
viewModule author project name status =
  case status of
    Success allDocs ->
      case findModule name allDocs of
        Just docs ->
          let
            header = h1 [ class "block-list-title" ] [ text name ]
            info = Block.makeInfo author project name allDocs
            blocks = List.map (Block.view info) (Docs.toBlocks docs)
          in
          div [ class "block-list" ] (header :: blocks)

        Nothing ->
          div
            (class "block-list" :: Problem.styles)
            (Problem.missingModule author project name)

    Loading ->
      div
        [ class "block-list" ]
        [ h1 [ class "block-list-title" ] [ text name ] ]

    Failure ->
      div
        (class "block-list" :: Problem.styles)
        (Problem.offline "docs.json")


findModule : String -> List Docs.Module -> Maybe Docs.Module
findModule name docsList =
  List.filter (checkModuleName name) docsList
    |> List.head


checkModuleName : String -> Docs.Module -> Bool
checkModuleName name docs =
  name == docs.name



-- Sidebar


viewSidebar : Model -> Html Msg
viewSidebar model =
  div
    [ class "pkg-nav"
    ]
    [ lazy3 viewReadmeLink model.author model.project model.focus
    , br [] []
    , h2 [] [ text "Module Docs" ]
    , input
        [ placeholder "Search"
        , value model.query
        , onInput QueryChanged
        ]
        []
    , viewSidebarModules model
    ]


viewSidebarModules : Model -> Html msg
viewSidebarModules model =
  case model.docs of
    Failure ->
      text ""

    Loading ->
      text ""

    Success modules ->
      if String.isEmpty model.query then
        let
          viewEntry docs =
            li [] [ viewModuleLink model docs.name ]
        in
        ul [] (List.map viewEntry modules)

      else
        let
          query =
            String.toLower model.query
        in
        ul [] (List.filterMap (viewSearchItem model query) modules)


viewSearchItem : Model -> String -> Docs.Module -> Maybe (Html msg)
viewSearchItem model query docs =
  let
    toItem ownerName valueName =
      viewValueItem model docs.name ownerName valueName

    matches =
      List.filterMap (isMatch query toItem) docs.binops
      ++ List.concatMap (isUnionMatch query toItem) docs.unions
      ++ List.filterMap (isMatch query toItem) docs.aliases
      ++ List.filterMap (isMatch query toItem) docs.values
  in
    if List.isEmpty matches && not (String.contains query docs.name) then
      Nothing

    else
      Just <|
        li
          [ class "pkg-nav-search-chunk"
          ]
          [ viewModuleLink model docs.name
          , ul [] matches
          ]


isMatch : String -> (String -> String -> b) -> { r | name : String } -> Maybe b
isMatch query toResult {name} =
  if String.contains query (String.toLower name) then
    Just (toResult name name)
  else
    Nothing


isUnionMatch : String -> (String -> String -> a) -> Docs.Union -> List a
isUnionMatch query toResult {name, tags} =
  let
    tagMatches =
      List.filterMap (isTagMatch query toResult name) tags
  in
    if String.contains query (String.toLower name) then
      toResult name name :: tagMatches
    else
      tagMatches


isTagMatch : String -> (String -> String -> a) -> String -> (String, details) -> Maybe a
isTagMatch query toResult tipeName (tagName, _) =
  if String.contains query (String.toLower tagName) then
    Just (toResult tipeName tagName)
  else
    Nothing



-- View README link


viewReadmeLink : String -> String -> Focus -> Html msg
viewReadmeLink author project focus =
  let
    url =
      Href.toProject author project
  in
    navLink "README" url <|
      case focus of
        Readme -> True
        _ -> False



-- View Module link


viewModuleLink : Model -> String -> Html msg
viewModuleLink model name =
  let
    url =
      Href.toModule model.author model.project name Nothing
  in
  navLink name url <|
    case model.focus of
      Module selectedName _ ->
        selectedName == name

      _ -> False


viewValueItem : Model -> String -> String -> String -> Html msg
viewValueItem { author, project } moduleName ownerName valueName =
  let
    url =
      Href.toModule author project moduleName (Just ownerName)
  in
  li [ class "pkg-nav-value" ] [ navLink valueName url False ]



-- Link Helpers


navLink : String -> String -> Bool -> Html msg
navLink name url isBold =
  let
    attributes =
      if isBold then
        [ class "pkg-nav-module"
        , style "font-weight" "bold"
        , style "text-decoration" "underline"
        ]
      else
        [ class "pkg-nav-module"
        ]
  in
  a (href url :: attributes) [ text name ]
