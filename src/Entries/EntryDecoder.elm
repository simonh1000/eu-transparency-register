module Entries.EntryDecoder (Id, Model, init, entryDecoder) where

import Json.Decode exposing (..)

type alias Id = String

type alias Model =
    { id: Id
    , orgName: String
    , hqCountry: String
    , euPerson: String
    , costEst: String
    , noFTEs: Float
    , memberships: String
    }

init : String -> String -> String -> String -> String -> Float -> String -> Model
init i o h e c n m =
    { id = i
    , orgName = o
    , hqCountry = h
    , euPerson = e
    , costEst = c
    , noFTEs = n
    , memberships = m
    }

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
