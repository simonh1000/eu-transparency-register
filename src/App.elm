module App (init, update, view) where

import Html exposing (..)
import Html.Attributes exposing (class)
import Http exposing (get)
import Json.Decode as Json exposing ( (:=) )

import Effects exposing (Effects)
import Task exposing (..)

import Filters.Filters as Filters exposing (Action(..))
import Matches.Matches as Matches exposing (Action(..))
import Entries.Entries as Entries exposing (Action(..))

-- MODEL

type alias Model =
    { filters : Filters.Model
    , matches : Matches.Model
    , entries : Entries.Model
    , message : String
    }

init : (Model, Effects Action)
init =
    ( { filters = Filters.init
      , matches = Matches.init
      , entries = Entries.init
      , message = "Loading"
      }
    , Effects.none )

-- UPDATE

type Action =
      FilterAction Filters.Action
    | MatchAction Matches.Action
    | EntryAction Entries.Action

update : Action -> Model -> (Model, Effects Action)
update action model =
    case action of
        FilterAction (GetMatch str) ->
            ( { model | message <- "Search for: " ++ str }
            , Effects.map MatchAction <| snd <| Matches.update (GetMatchFor str) model.matches
            )
        FilterAction filterAction ->
            let
                filters' = Filters.update filterAction model.filters
            in ( { model | filters <- fst filters'}, Effects.none )

        MatchAction (GetEntry id) ->
            ( { model | message <- "get entry for " ++ id }
            , Effects.map EntryAction <| snd <| Entries.update (GetEntryFor id) model.entries
            )
        MatchAction matchAction ->
            let
                matches' = Matches.update matchAction model.matches
            in  ( { model | matches <- fst matches'}
                , Effects.map MatchAction <| snd <| matches'
                )

        EntryAction entryAction ->
            let
                entries' = Entries.update entryAction model.entries
            in  ( { model | entries <- fst entries' }
                , Effects.map EntryAction <| snd <| entries'
                )


-- VIEW

view : Signal.Address Action -> Model -> Html
view address model =
    div [ class "container" ]
        [ nav [] []
        , Filters.view (Signal.forwardTo address FilterAction) model.filters
        , div [ class "row" ]
            [ div [ class "col-sm-4" ]
                [ Matches.view (Signal.forwardTo address MatchAction) model.matches ]
            , div [ class "col-sm-8" ]
                [ Entries.view (Signal.forwardTo address EntryAction) model.entries ]
            ]
        , p [ ] [ text model.message ]
        ]

-- TASKS
-- loadData : Effects Action
-- loadData =
--     Http.get ("data" := Json.string) "http://localhost:3000/api/default"
--         |> Task.toMaybe
--         |> Task.map Data
--         |> Effects.task
