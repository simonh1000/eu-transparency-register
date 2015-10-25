module Matches.MatchesDecoder (Id, Model, matchesDecoder) where

import Json.Decode exposing ( Decoder, (:=), object2, list, string )

type alias Id = String

type alias Model =
    { id: Id
    , orgName: String
    }

init : String -> String -> Model
init i o =
    { id = i
    , orgName = o
    }

matchesDecoder : Decoder (List Model)
matchesDecoder =
    list matchDecoder

matchDecoder : Decoder Model
matchDecoder =
    object2
        init
        ( "_id" := string )
        ( "orgName" := string )
