module Session exposing (Data, empty, getReadme, addReadme, fetchReadme, getDocs, addDocs, fetchDocs)

import Dict
import Elm.Docs as Docs
import Http
import Json.Decode as Decode
import Url.Builder as Url



type alias Data =
  { readmes : Dict.Dict String String
  , docs : Dict.Dict String (List Docs.Module)
  }


empty : Data
empty =
  Data Dict.empty Dict.empty



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

