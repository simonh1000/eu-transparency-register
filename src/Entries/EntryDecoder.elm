module Entries.EntryDecoder (Id, Model, entryDecoder) where

import Json.Decode exposing ( Decoder, (:=), object2, list, string )

type alias Id = String

type alias Model = String
    -- { id: Id
    -- , orgName: String
    -- }

init : String -> Model
init i = i
    -- { id = i
    -- , orgName = o
    -- }

entryDecoder : Decoder Model
entryDecoder =
    "orgName" := string
    -- object2
    --     init
    --     ( "_id" := string )
    --     ( "orgName" := string )
