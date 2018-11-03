module Href exposing (toProject, toModule)

import Url.Builder as Url



toProject : String -> String -> String
toProject author project =
  Url.absolute [ "packages", author, project ] []


toModule : String -> String -> String -> Maybe String -> String
toModule author project moduleName maybeValue =
  Url.custom
    Url.Absolute
    [ "packages", author, project, String.replace "." "-" moduleName ]
    []
    maybeValue
