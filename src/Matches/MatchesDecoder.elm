module Matches.MatchesDecoder (Id, NewStuff, Model, matchesDecoder, recentsDecoder) where

import Json.Decode as Json exposing ( Decoder, (:=), object2, list, string )

type alias Id = String

type alias Model =
    { id: Id
    , orgName: String
    }

-- init : String -> String -> Model
-- init i o =
--     { id = i
--     , orgName = o
--     }

type alias NewStuff =
    { entries: List Model
    , updates: List Model
    }
-- initNew : List Model -> List Model -> NewStuff
-- initNew e u = { entries = e, updates = u }

-- ************
recentsDecoder : Decoder NewStuff
recentsDecoder =
    object2
        NewStuff
        ( "entries" := matchesDecoder )
        ( "updates" := matchesDecoder )

matchesDecoder : Decoder (List Model)
matchesDecoder =
    list matchDecoder

matchDecoder : Decoder Model
matchDecoder =
    object2
        Model
        ( "_id" := string )
        ( "orgName" := string )
