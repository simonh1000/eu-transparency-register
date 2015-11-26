module Matches.Matches (Model, Action(..), init, update, view) where

import Html exposing (..)
import Html.Attributes exposing (class, id)
import Html.Events exposing (onClick, on, targetValue)

import Http exposing (get)
import Effects exposing (Effects)
import Task exposing (..)

import Filters.Filters as Filters
import Matches.MatchesDecoder as MatchesDecoder exposing (Id, matchesDecoder)

-- MODEL

type alias Match = MatchesDecoder.Model
type alias NewStuff = MatchesDecoder.NewStuff

type ResultsType
    = Filtered
    | Recents

type alias Model =
    { matches : List Match
    , newstuff: NewStuff
    , searching : Bool
    , resultsType : ResultsType
    , message : String
    }

init : Model
init =
    { matches = []
    , newstuff = MatchesDecoder.initNew [] []
    , searching = False
    , resultsType = Filtered
    , message = "Use the filters above to find some registrees" }

-- UPDATE

type Action
    = SetRegister
    | GetMatchFor Filters.Model
    | MatchesData (Result Http.Error (List Match))
    | GetRecents
    | RecentsData (Result Http.Error NewStuff)
    | GetEntry Id                   -- caught by App

update : Action -> Model -> (Model, Effects Action)
update action model =
    case action of
        SetRegister ->
            ( { model | resultsType = Filtered }
            , Effects.none
            )
        GetMatchFor searchModel ->
            ( { model
                | matches = []
                , message = "Searching...."
                , resultsType = Filtered
                }
            , getMatches searchModel
            )
        MatchesData (Result.Ok ms) ->
            ( { model |
                matches = ms
              , message = if List.length ms == 0 then "No results found" else "" }
            , Effects.none
            )
        MatchesData (Result.Err err) ->
            ( { model | message = errorHandler err }
            , Effects.none
            )
        GetRecents ->
            ( { model
                | message = "Getting data..."
                , resultsType = Filtered
              }
            , getRecents )     -- if no data already in model then ....
        RecentsData (Result.Ok recs) ->
            ( { model |
                resultsType = Recents
              , message = ""
              , newstuff = recs
              }
            , Effects.none
            )
        RecentsData (Result.Err err) ->
            ( { model | message = errorHandler err }
            , Effects.none
            )
        -- caught by parent in practise
        GetEntry _ -> ( model, Effects.none )

errorHandler : Http.Error -> String
errorHandler err =
    case err of
        Http.UnexpectedPayload s -> s
        otherwise -> "http error"

-- VIEW

view : Signal.Address Action -> Model -> Html
view address model =
    case model.resultsType of
        Filtered -> viewFilterResults address model
        Recents -> viewRecents address model

viewFilterResults : Signal.Address Action -> Model -> Html
viewFilterResults address model =
    div [ id "matches", class "col-xs-12 col-sm-4" ]
        [ h2 [] [ text "Search results" ]
        , p [] [ text model.message ]
        , div [ class "mainContainer" ] <| List.map (viewMatch address) model.matches
        ]

viewRecents : Signal.Address Action -> Model -> Html
viewRecents address model =
    div [ id "matches", class "col-xs-12 col-sm-4" ]
        -- , p [] [ text model.message ]
        [ div [ class "recent entries" ]
            [ h2 [] [ text <| (toString <| List.length model.newstuff.entries) ++ " Recent new entries" ]
            , div [ class "mainContainer" ] <| List.map (viewMatch address) model.newstuff.entries
            ]
        , div [ class "recent entries" ]
            [ h2 [] [ text <| (toString <| List.length model.newstuff.updates) ++ " Recent updates" ]
            , div [ class "mainContainer" ] <| List.map (viewMatch address) model.newstuff.updates
            ]
        ]

viewMatch : Signal.Address Action -> Match -> Html
viewMatch address match =
    p [ onClick address (GetEntry match.id) ] [ text match.orgName ]

-- TASKS

getMatches : Filters.Model -> Effects Action
getMatches model =
    let
        sect =
            if model.section == "All"
            then []
            else [("section", model.section)]
        cntry =
            if model.country == "All"
            then []
            else [("country", model.country)]
        searchTerms =
            List.concat [ sect, cntry ] ++
            [ ("search", model.search)
            , ("fte", model.fte)
            , ("budget", model.budget)
            ]
    in
    Http.get matchesDecoder (Http.url "/api/register/search/" searchTerms)
        |> Task.toResult
        |> Task.map MatchesData
        |> Effects.task

getRecents : Effects Action
getRecents =
    Http.get MatchesDecoder.recentsDecoder ("/api/register/recents")
        |> Task.toResult
        |> Task.map RecentsData
        |> Effects.task
