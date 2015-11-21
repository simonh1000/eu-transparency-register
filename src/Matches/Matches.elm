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
    = FilterMatches
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
    , resultsType = FilterMatches
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
            ( { model | resultsType = FilterMatches }
            , Effects.none
            )
        GetMatchFor searchModel ->
            ( { model | matches = [], message = "Searching...." }
            , getMatches searchModel
            )
        MatchesData (Result.Ok ms) ->
            ( { model |
                matches = ms
              , resultsType = FilterMatches
              , message = if List.length ms == 0 then "No results found" else "" }
            , Effects.none
            )
        MatchesData (Result.Err err) ->
            ( { model | message = errorHandler err }
            , Effects.none
            )
        GetRecents ->
            ( model
            , getRecents )     -- if no data aslready in model then ....
        RecentsData (Result.Ok recs) ->
            ( { model |
                resultsType = Recents
              , newstuff = recs
              }
            , Effects.none
            )
        RecentsData (Result.Err err) ->
            ( { model | message = errorHandler err }
            , Effects.none
            )
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
        FilterMatches -> viewFilterResults address model
        Recents -> viewRecents address model

viewFilterResults : Signal.Address Action -> Model -> Html
viewFilterResults address model =
    div [ id "matches", class "col-xs-12 col-sm-4" ]
        [ h2 [] [ text "Search results" ]
        , p [] [ text model.message ]
        , div [ class "mContainer" ] <| List.map (viewMatch address) model.matches
        ]

viewRecents : Signal.Address Action -> Model -> Html
viewRecents address model =
    div [ id "matches", class "col-xs-12 col-sm-4" ]
        [ div [ class "recent entries" ]
            [ h2 [] [ text <| (toString <| List.length model.newstuff.entries) ++ " Recent new entries" ]
            , div [ class "mContainer" ] <| List.map (viewMatch address) model.newstuff.entries
            ]
        , div [ class "recent entries" ]
            [ h2 [] [ text <| (toString <| List.length model.newstuff.updates) ++ " Recent updates" ]
            , div [ class "mContainer" ] <| List.map (viewMatch address) model.newstuff.updates
            ]
        ]
        -- , p [] [ text model.message ]

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
