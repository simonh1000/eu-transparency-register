module Matches.Matches (Model, Action(..), DisplayView(..), init, update, view) where

import Html exposing (..)
import Html.Attributes exposing (class, id)
import Html.Events exposing (onClick, on, targetValue)

import Http exposing (get)
import Effects exposing (Effects)
import Task exposing (..)
import Common exposing (errorHandler)

import Filters.Filters as Filters
import Matches.MatchesDecoder as MatchesDecoder exposing (Id, matchesDecoder)

-- MODEL

type alias Match = MatchesDecoder.Model
type alias NewStuff = MatchesDecoder.NewStuff

type DisplayView
    = Filtered
    | Recents

defaultMessage = "Use the filters above to find some registrees"

type alias Model =
    { display : DisplayView
    , matches : List Match
    , newstuff: NewStuff
    , loading : Bool
    , message : String
    }

init : Model
init =
    Model Filtered [] (MatchesDecoder.NewStuff [] []) False ""

-- UPDATE

type Action
    = SetFilters
    | GetMatchFor Filters.Model
    | MatchesData (Result Http.Error (List Match))
    | GetRecents
    | RecentsData (Result Http.Error NewStuff)
    | GetEntry Id                   -- caught by App
    | Reset

update : Action -> Model -> (Model, Effects Action)
update action model =
    case action of
        SetFilters ->
            ( { model | display = Filtered }
            , Effects.none
            )
        GetMatchFor searchModel ->
            ( { model
                | matches = []
                , loading = True
                , display = Filtered
                }
            , getMatches searchModel
            )
        MatchesData (Result.Ok ms) ->
            ( { model
              | matches = ms
              , loading = False
              , message = if List.length ms == 0 then "No results match your query" else ""
              }
            , Effects.none
            )
        MatchesData (Result.Err err) ->
            ( { model | message = errorHandler err }
            , Effects.none
            )
        GetRecents ->
            let newModel =
                { model | display = Recents }
            in
                if List.length model.newstuff.entries == 0
                    then ( { newModel | loading = True }, getRecents )
                    else ( { newModel | loading = False }, Effects.none )

        RecentsData (Result.Ok recs) ->
            ( { model
              | loading = False
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
        Reset ->
            ( { model | matches = [], display = Filtered, message = "" }
            , Effects.none
            )

-- VIEW

view : Signal.Address Action -> Model -> Html
view address model =
    case model.display of
        Filtered -> viewFilterResults address model
        Recents -> viewRecents address model

viewFilterResults : Signal.Address Action -> Model -> Html
viewFilterResults address model =
    div [ id "matches", class "col-xs-12 col-sm-4" ] <|
        if model.message /= ""
        then [ h2 [] [ text model.message ] ]
        else if model.loading
            then
                [ h2 [] [ text "Loading..." ] ]
            else
                [ h2 [] [ text <| (toString <| List.length model.matches) ++ " Search results" ]
                , div [ class "mainContainer" ] <| List.map (viewMatch address) model.matches
                ]

viewRecents : Signal.Address Action -> Model -> Html
viewRecents address model =
    div [ id "matches", class "col-xs-12 col-sm-4" ] <|
        if model.loading
        then
            [ h2 [] [ text "Loading..." ] ]
        else
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
