module Main exposing (main)

import Browser
import Browser.Navigation as Nav
import Url
import Url.Parser as Parser exposing (Parser, (</>), custom, fragment, map, oneOf, s, top)

import Page.Docs as Docs
import Page.Problem as Problem
import Session
import Skeleton


{- ****************
   Main
   **************** -}

main =
  Browser.application
    { init = init
    , view = view
    , update = update
    , subscriptions = subscriptions
    , onUrlRequest = LinkClicked
    , onUrlChange = UrlChanged
    }


{- ****************
   Model
   **************** -}

type alias Model =
  { key : Nav.Key
  , page : Page
  }

type Page
  = NotFound Session.Data
  | Docs Docs.Model


{- **************
   Subscriptions
   ************** -}


subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none



{- **************
   View
   ************** -}


view : Model -> Browser.Document Msg
view model =
  case model.page of
    NotFound _ ->
      Skeleton.view never
        { title = "Not Found"
        , header = []
        , attrs = Problem.styles
        , kids = Problem.notFound
        }

    Docs docs ->
      Skeleton.view DocsMsg (Docs.view docs)



{- ***************
   Init
   *************** -}

init : () -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init _ url key =
  stepUrl url
    { key = key
    , page = NotFound Session.empty
    }



{- *************
   Update
   ************* -}


type Msg
  = NoOp
  | LinkClicked Browser.UrlRequest
  | UrlChanged Url.Url
  | DocsMsg Docs.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update message model =
  case message of
    NoOp ->
      ( model, Cmd.none )

    LinkClicked urlRequest ->
      case urlRequest of
        Browser.Internal url ->
          ( model
          , Nav.pushUrl model.key (Url.toString url)
          )

        Browser.External href ->
          ( model
          , Nav.load href
          )

    UrlChanged url ->
      stepUrl url model

    DocsMsg msg ->
      case model.page of
        Docs docs -> stepDocs model (Docs.update msg docs)
        _         -> ( model, Cmd.none )


stepDocs : Model -> ( Docs.Model, Cmd Docs.Msg ) -> ( Model, Cmd Msg )
stepDocs model (docs, cmds) =
  ( { model | page = Docs docs }
  , Cmd.map DocsMsg cmds
  )



{- *****************
   Router
   ***************** -}


stepUrl : Url.Url -> Model -> (Model, Cmd Msg)
stepUrl url model =
  let
    session =
      exit model

    parser =
      oneOf
        [ route (s "packages" </> author_ </> project_ </> focus_)
            (\author project focus ->
                stepDocs model (Docs.init session author project focus)
            )
        ]
  in
  case Parser.parse parser url of
    Just answer ->
      answer

    Nothing ->
      ( { model | page = NotFound session }
      , Cmd.none
      )


exit : Model -> Session.Data
exit model =
  case model.page of
    NotFound session -> session
    Docs m -> m.session


route : Parser a b -> a -> Parser (b -> c) c
route parser handler =
  Parser.map handler parser


author_ : Parser (String -> a) a
author_ =
  custom "AUTHOR" Just


project_ : Parser (String -> a) a
project_ =
  custom "PROJECT" Just


focus_ : Parser (Docs.Focus -> a) a
focus_ =
  oneOf
    [ map Docs.Readme top
    , map Docs.Module (moduleName_ </> fragment identity)
    ]


moduleName_ : Parser (String -> a) a
moduleName_ =
  custom "MODULE" (Just << String.replace "-" ".")
