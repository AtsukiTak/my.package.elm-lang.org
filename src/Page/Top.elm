module Page.Top exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)

import Session
import Skeleton
import Href



{- **********
   Model
   ********** -}


type alias Model =
  { session : Session.Data
  , entries : List Entry
  }


type alias Entry =
  { author : String
  , project : String
  , summary : String
  }


init : Session.Data -> ( Model, Cmd msg )
init session =
  ( Model session entryList
  , Cmd.none
  )



view : Model -> Skeleton.Details msg
view model =
  { title = "My Elm Packages"
  , header = []
  , attrs = []
  , kids =
    [ viewEntries entryList
    ]
  }


viewEntries : List Entry -> Html msg
viewEntries entries =
  div [ class "catalog" ]
  [ div []
    (List.map viewEntry entries)
  ]


viewEntry : Entry -> Html msg
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



{- **************
   Entries
   ************** -}

entryList : List Entry
entryList =
  [ Entry "elm" "core" "Elm's standard libraries"
  ]
