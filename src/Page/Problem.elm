module Page.Problem exposing (..)


import Html exposing (..)
import Html.Attributes exposing (..)
import Href



-- NOT FOUND


notFound : List (Html msg)
notFound =
  [ div [ style "font-size" "12em" ] [ text "404" ]
  , div [ style "font-size" "3em" ] [ text "I cannot find this page!" ]
  ]


styles : List (Attribute msg)
styles =
  [ style "text-align" "center"
  , style "color" "#9A9A9A"
  , style "padding" "6em 0"
  ]



-- OFFLINE


offline : String -> List (Html msg)
offline file =
  [ div
    [ style "font-size" "3em" ]
    [ text "Cannot find "
    , code [] [ text file ]
    ]
  , p [] [ text "Are you offline or something?" ]
  ]



-- MISSING MODULE


missingModule : String -> String -> String -> List (Html msg)
missingModule author project name =
  [ div
    [ style "font-size" "3em" ]
    [ text "Module not found"
    ]
  , p []
    [ text "Maybe the "
    , a [ href (Href.toProject author project) ] [ text "README" ]
    , text " will help you figure out what changed?"
    ]
  ]
