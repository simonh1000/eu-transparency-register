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
    , goals: String
    }

init : String -> String -> String -> String -> String -> Float -> String -> String -> Model
init i o h e c n m g =
    { id = i
    , orgName = o
    , hqCountry = h
    , euPerson = e
    , costEst = c
    , noFTEs = n
    , memberships = m
    , goals = g
    }

entryDecoder : Decoder Model
entryDecoder =
    object8
        init
        ( "_id" := string )
        ( "orgName" := string )
        ( "hqCountry" := string )
        ( "euPerson" := string )
        costs
        ( "noFTEs" := float )
        maybeMemberships
        ( "goals" := string )

maybeMemberships : Decoder String
maybeMemberships =
    oneOf
        [ "memberships" := string
        , succeed "None"
        ]

costs : Decoder String
costs =
    oneOf
        [ map toString ("costsAbsolute" := int)
        , "costEst" := string
        ]
