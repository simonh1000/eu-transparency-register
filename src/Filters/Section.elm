module Filters.Section (sections, subsections) where

import Html exposing (..)
import Html.Attributes exposing (class, id, type')
import Html.Events exposing (onClick, on, targetValue)

sections : List String
sections =
    [ "I - Professional consultancies/law firms/self-employed consultants"
    , "II - In-house lobbyists and trade/business/professional associations"
    , "V - Organisations representing churches and religious communities"
    , "IV - Think tanks, research and academic institutions"
    , "III - Non-governmental organisations"
    , "VI - Organisations representing local, regional and municipal authorities, other public or mixed entities, etc."
    ]

subsections =
    [ "All"
    , "Professional consultancies"
    , "Companies & groups"
    , "Organisations representing churches and religious communities"
    , "Self-employed consultants"
    , "Academic institutions"
    , "Trade and business associations"
    , "Non-governmental organisations, platforms and networks and similar"
    , "Law firms"
    , "Think tanks and research institutions"
    , "Trade unions and professional associations"
    , "Other organisations"
    , "Other public or mixed entities, created by law whose purpose is to act in the public interest"
    , "Other sub-national public authorities"
    , "Transnational associations and networks of public regional or other sub-national authorities"
    , "Regional structures"
    ]
