module Session exposing (Data, Entry, empty, getEntries, replaceEntries, fetchEntries, getReadme, addReadme, fetchReadme, getDocs, addDocs, fetchDocs)

import Dict
import Elm.Docs as Docs
import Http
import Json.Decode as Decode
import Url.Builder as Url



type alias Data =
  { entries : Maybe (List Entry)
  , readmes : Dict.Dict String String
  , docs : Dict.Dict String (List Docs.Module)
  }


empty : Data
empty =
  Data Nothing Dict.empty Dict.empty



{- *************
   Entry
   ************* -}


type alias Entry =
  { author : String
  , project : String
  , summary : String
  }


getEntries : Data -> Maybe (List Entry)
getEntries data =
  data.entries


replaceEntries : List Entry -> Data -> Data
replaceEntries newEntries data =
  { data | entries = Just newEntries }


fetchEntries : Http.Request (List Entry)
fetchEntries =
  Http.get
    (Url.absolute [ "assets", "packages", "packages.json" ] [])
    (Decode.list entryDecoder)


entryDecoder : Decode.Decoder Entry
entryDecoder =
  Decode.map3 Entry
    (Decode.field "author" Decode.string)
    (Decode.field "project" Decode.string)
    (Decode.field "summary" Decode.string)


{- *************
   Readme
   ************* -}


toProjectKey : String -> String -> String
toProjectKey author project =
  author ++ "/" ++ project


getReadme : Data -> String -> String -> Maybe String
getReadme data author project =
  Dict.get (toProjectKey author project) data.readmes


addReadme : String -> String -> String -> Data -> Data
addReadme author project readme data =
  let
    newReadmes =
      Dict.insert (toProjectKey author project) readme data.readmes
  in
  { data | readmes = newReadmes }


fetchReadme : String -> String -> Http.Request String
fetchReadme author project =
  Http.getString <|
    Url.absolute [ "assets", "packages", author, project, "README.md" ] []



{- *************
   Docs
   ************* -}


getDocs : Data -> String -> String -> Maybe (List Docs.Module)
getDocs data author project =
  Dict.get (toProjectKey author project) data.docs


addDocs : String -> String -> List Docs.Module -> Data -> Data
addDocs author project docs data =
  let
    newDocs =
      Dict.insert (toProjectKey author project) docs data.docs
  in
  { data | docs = newDocs }


fetchDocs : String -> String -> Http.Request (List Docs.Module)
fetchDocs author project =
  Http.get
    (Url.absolute [ "assets", "packages", author, project, "docs.json" ] [])
    (Decode.list Docs.decoder)

