module Page.Top exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Http

import Page.Problem as Problem
import Session
import Skeleton
import Href



{- **********
   Model
   ********** -}


type alias Model =
  { session : Session.Data
  , entries : Status (List Session.Entry)
  }



type Status a
  = Failure
  | Loading
  | Success a


init : Session.Data -> ( Model, Cmd Msg )
init session =
  case Session.getEntries session of
    Nothing ->
      ( Model session Loading
      , Http.send GotEntries (Session.fetchEntries)
      )

    Just entries ->
      ( Model session (Success entries)
      , Cmd.none
      )



{- *************
   Update
   ************* -}


type Msg
  = GotEntries (Result Http.Error (List Session.Entry))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  case msg of
    GotEntries result ->
      case result of
        Err _ ->
          ( { model | entries = Failure }
          , Cmd.none
          )

        Ok entries ->
          ( { model
              | entries = Success entries
              , session = Session.replaceEntries entries model.session
            }
          , Cmd.none
          )



{- **************
   View
   ************** -}


view : Model -> Skeleton.Details msg
view model =
  { title = "My Elm Packages"
  , header = []
  , attrs = []
  , kids =
    [ viewEntries model.entries
    ]
  }


viewEntries : Status (List Session.Entry) -> Html msg
viewEntries status =
  case status of
    Success entries ->
      div [ class "catalog" ]
        [ div []
          (List.map viewEntry entries)
        ]

    Loading ->
      div [ class "catalog" ] []

    Failure ->
      div
        (class "catalog" :: Problem.styles)
        (Problem.offline "packages.json")


viewEntry : Session.Entry -> Html msg
viewEntry ({ author, project, summary } as entry) =
  div [ class "pkg-summary" ]
  [ div []
    [ h1 []
      [ a [ href (Href.toProject author project) ]
          [ span [ class "light" ] [ text (author ++ "/") ]
          , text project
          ]
      ]
    ]
  , p [ class "pkg-summary-desc" ] [ text summary ]
  ]
