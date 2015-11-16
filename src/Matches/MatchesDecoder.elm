module Matches.MatchesDecoder (Id, NewStuff, Model, initNew, matchesDecoder, recentsDecoder) where

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

type alias NewStuff =
    { entries: List Model
    , updates: List Model
    }
initNew : List Model -> List Model -> NewStuff
initNew e u = { entries = e, updates = u }

-- **************
matchDecoder : Decoder Model
matchDecoder =
    object2
        init
        ( "_id" := string )
        ( "orgName" := string )

matchesDecoder : Decoder (List Model)
matchesDecoder =
    list matchDecoder

recentsDecoder : Decoder NewStuff
recentsDecoder =
    object2
        initNew
        ( "entries" := matchesDecoder )
        ( "updates" := matchesDecoder )
