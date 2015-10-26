module Entries.EntryModel (Id, Model, init) where

type alias Id = String

type alias Model =
    { id: Id
    , orgName: String
    , hqCountry: String
    , euPerson: String
    , costEst: String
    , noFTEs: Float
    , memberships: String
    , expand : Bool
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
    , expand = False
    }
