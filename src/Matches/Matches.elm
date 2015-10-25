module Matches.Matches (Model, Action(..), init, update, view) where

import Html exposing (..)
import Html.Attributes exposing (class, id, type', href)
import Html.Events exposing (onClick, on, targetValue)
import Http exposing (get)


import Effects exposing (Effects)
import Task exposing (..)

import Matches.MatchesDecoder as MatchesDecoder exposing (Id, matchesDecoder)

-- MODEL

type alias Match = MatchesDecoder.Model

type alias Model =
    { matches : List Match
    , message : String
    }

init : Model
init =
    { matches = [], message = "" }

type Action =
      GetMatchFor String       -- equivalent to Filters
    -- | MatchesReceived (Maybe Model)
    | MatchesReceived (Result Http.Error (List Match))
    | GetEntry Id

update : Action -> Model -> (Model, Effects Action)
update action model =
    case action of
        GetMatchFor s ->
            ( model, loadMatches s)
        MatchesReceived (Result.Ok ms) ->
            ( { model  | matches <- ms }, Effects.none )
        MatchesReceived (Result.Err msg) ->
            ( model, Effects.none )

view : Signal.Address Action -> Model -> Html
view address model =
    div [ id "matches" ]
        [ div []
            [ h2 [] [ text "Matches" ]
            , div [ class "mContainer" ] <| List.map (viewMatch address) model.matches
            ]
        , p [] [ text model.message ]
        ]

viewMatch : Signal.Address Action -> Match -> Html
viewMatch address match =
    p [ onClick address (GetEntry match.id) ] [ text match.orgName ]

-- TASKS
loadMatches : String -> Effects Action
loadMatches s =
    Http.get matchesDecoder ("http://localhost:3000/api/register/search/" ++ s)
        |> Task.toResult
        |> Task.map MatchesReceived
        |> Effects.task
