module Matches.Matches (Model, Action(..), init, update, view) where

import Html exposing (..)
import Html.Attributes exposing (class, id, type', href)
import Html.Events exposing (onClick, on, targetValue)
import Http exposing (get)


import Effects exposing (Effects)
import Task exposing (..)

import Filters.Filters as Filters
import Matches.MatchesDecoder as MatchesDecoder exposing (Id, matchesDecoder)

-- MODEL

type alias Match = MatchesDecoder.Model

type alias Model =
    { matches : List Match
    , searching : Bool
    , message : String
    }

init : Model
init =
    { matches = [], searching = False, message = "" }

type Action =
      GetMatchFor Filters.Model
    | MatchesReceived (Result Http.Error (List Match))
    | GetEntry Id

update : Action -> Model -> (Model, Effects Action)
update action model =
    case action of
        GetMatchFor searchModel ->
            ( { model | matches <- [], message <- "Searching...." }
            , getMatches searchModel)
        MatchesReceived (Result.Ok ms) ->
            ( { model |
                matches <- ms,
                message <- if List.length ms == 0 then "No results found" else "" }
            , Effects.none )
        MatchesReceived (Result.Err msg) ->
            ( { model | message <- "An error has occurred. Try again or report to author" }
            , Effects.none )

view : Signal.Address Action -> Model -> Html
view address model =
    div [ id "matches" ]
        [ h2 [] [ text "Search results" ]
        , p [] [ text model.message ]
        , div [ class "mContainer" ] <| List.map (viewMatch address) model.matches
        ]

viewMatch : Signal.Address Action -> Match -> Html
viewMatch address match =
    p [ onClick address (GetEntry match.id) ] [ text match.orgName ]

-- TASKS
getMatches : Filters.Model -> Effects Action
getMatches model =
    let
        searchTerms =
            [ ("search", model.search)
            , ("fte", model.fte)
            , ("budget", model.budget)
            ] ++
                if model.section == "All"
                then []
                else [("section", model.section)]
        query =
            Http.url "/api/register/search/" searchTerms
    in
    Http.get matchesDecoder query
    -- Http.get matchesDecoder ("http://localhost:3000/api/register/search/" ++ s)
        |> Task.toResult
        |> Task.map MatchesReceived
        |> Effects.task
