module Skeleton exposing (..)

import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Lazy exposing (..)

import Href
import Utils.Logo as Logo



type alias Details msg =
  { title : String
  , header : List Segment
  , attrs : List (Attribute msg)
  , kids : List (Html msg)
  }


type Segment
  = Text String
  | Link String String


authorSegment : String -> Segment
authorSegment author =
  Text author


projectSegment : String -> String -> Segment
projectSegment author project =
  Link (Href.toProject author project) project


moduleSegment : String -> String -> String -> Segment
moduleSegment author project moduleName =
  Link (Href.toModule author project moduleName Nothing) moduleName


view : (a -> msg) -> Details a -> Browser.Document msg
view toMsg details =
  { title = details.title
  , body =
      [ viewHeader details.header
      , Html.map toMsg <|
          div (class "center" :: details.attrs) details.kids
      , viewFooter
      ]
  }



-- View header


viewHeader : List Segment -> Html msg
viewHeader segments =
  div
    [ style "background-color" "#eee"
    ]
    [ div
      [ class "center" ]
      [ h1
        [ class "header" ]
        (viewLogo :: List.intersperse slash (List.map viewSegment segments))
      ]
    ]


slash : Html msg
slash =
  span [ class "spacey-char" ] [ text "/" ]


viewSegment : Segment -> Html msg
viewSegment segment =
  case segment of
    Text string ->
      text string

    Link address string ->
      a [ href address ] [ text string ]



-- View Footer


viewFooter : Html msg
viewFooter =
  div
    [ class "footer" ]
    [ text "All code for this site is open source and written in Elm. "
    ]



-- View Logo


viewLogo : Html msg
viewLogo =
  a [ href "/"
    , style "text-decoration" "none"
    ]
    [ div
      [ style "display" "-webkit-display"
      , style "display" "-ms-flexbox"
      , style "display" "flex"
      ]
      [ Logo.logo 30
      , div
        [ style "color" "black"
        , style "padding-left" "8px"
        ]
        [ div [ style "line-height" "20px" ] [ text "elm" ]
        , div
          [ style "line-height" "10px"
          , style "font-size" "0.5em"
          ]
          [ text "packages" ]
        ]
      ]
    ]
