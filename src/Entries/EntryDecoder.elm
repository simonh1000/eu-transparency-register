module Entries.EntryDecoder (entryDecoder) where

import Json.Decode exposing (..)
import Entries.EntryModel exposing (init, Model)

entryDecoder : Decoder Model
entryDecoder =
    object7
        init
        ( "_id" := string )
        ( "orgName" := string )
        ( "hqCountry" := string )
        ( "euPerson" := string )
        costs
        ( "noFTEs" := float )
        maybeMemberships

maybeMemberships : Decoder String
maybeMemberships =
    oneOf
        [ "memberships" := string
        , succeed "None"
        ]

costs : Decoder String
costs =
    oneOf
        [ "costEst" := string
        , map toString ("costsAbsolute" := int)
        ]
