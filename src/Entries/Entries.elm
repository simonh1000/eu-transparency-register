module Entries.Entries (Model, Action(..), init, update, view) where

import Html exposing (..)
import Html.Attributes exposing (class, id, type', href, style)
import Html.Events exposing (onClick, on, targetValue)
import List exposing (take, drop)
import Dict exposing (Dict, insert, get)

import Http
import Effects exposing (Effects)
import Task exposing (..)

import Entries.EntryDecoder as EntryDecoder exposing (Id, Model, entryDecoder)
import Entries.Entry as Entry exposing (Action(..))

-- MODEL

type alias Cache = Dict Id (Entry.Model)

type alias Model =
    { displayed : List Id
    , cache : Cache       -- also contains info about whether an item is exapanded
    , message : String
    }

init : Model
init =
    { displayed = []
    , cache = Dict.empty
    , message = ""
    }

-- UPDATE

type Action =
      GetEntryFor Id
    | EntryReceived (Result Http.Error EntryDecoder.Model)  -- Decoder brings in raw data
    | CloseAll
    | EntryAction Id Entry.Action

update : Action -> Model -> (Model, Effects Action)
update action model =
    case action of
        GetEntryFor id ->
            -- if Dict.member id model.cache
            -- then
            -- TEST WHETHER ALREADY CACHED
            (model, loadEntry id )
        EntryReceived (Result.Ok entry) ->
          if List.member entry.id model.displayed
          then
            ( model, Effects.none )
          else
            ( { model |
                  displayed <- entry.id :: model.displayed
                , cache <- insert entry.id (Entry.init entry) model.cache
              }
            , Effects.map (EntryAction entry.id) (Effects.tick Entry.Tick)       -- starts animation
            )
        EntryReceived (Result.Err msg) ->
            ( { model | message <- errorHandler msg }
            , Effects.none
            )
        CloseAll ->
            ( { model | displayed <- [] }, Effects.none )
        EntryAction id Close ->
            ( { model | displayed <- List.filter (\d -> d /= id) model.displayed }
            , Effects.none
            )
        EntryAction id entryAction ->    -- i.e. Expand
            -- update : comparable -> (Maybe Entry -> Maybe Entry) -> Dict comparable Entry -> Dict comparable Entry
            let
                (Just entry) = get id model.cache
                (newEntry, newEffect) = Entry.update entryAction entry
            in
            ( { model | cache <- Dict.update id (\_ -> Just newEntry) model.cache }
            , Effects.map (EntryAction id) newEffect
            )

errorHandler : Http.Error -> String
errorHandler err =
    case err of
        Http.UnexpectedPayload s -> s
        otherwise -> "http error"


-- VIEW

view : Signal.Address Action -> Model -> Html
view address model =
    let
        viewMapper : Id -> Html
        viewMapper id =
            let (Just entry) = get id model.cache
            in Entry.view (Signal.forwardTo address (EntryAction id)) entry
    in
    div [ id "entries" ]
        [ header []
            [ h2 [] [ text "Entries" ]
            , button
                [ onClick address CloseAll
                , class "btn btn-default btn-xs closeAll" ]
                [ text "Close All" ]
            ]
        , div [ class "eContainer" ]
            -- <| List.indexedMap viewMapper model.displayed
            <| List.map viewMapper model.displayed
            -- <| List.map (\e -> Entry.view (Signal.forwardTo address (EntryAction e.id)) e) model.displayed
        -- , p [] [ text <| offsetValue model.animationState ]
        ]
-- TASKS

loadEntry : Id -> Effects Action
loadEntry id =
    Http.get entryDecoder ("http://localhost:3000/api/register/id/" ++ id)
        |> Task.toResult
        |> Task.map EntryReceived
        |> Effects.task
