module Entries.Entries (Model, Action(..), init, update, view) where

import Html exposing (..)
import Html.Attributes exposing (class, id, type', href)
import Html.Events exposing (onClick, on, targetValue)
import Http
import List exposing (take, drop)
-- import Array exposing (Array, append)
import Dict exposing (Dict, insert, get)

import Effects exposing (Effects)
import Task exposing (..)

import Entries.EntryDecoder as EntryDecoder exposing (entryDecoder)
import Entries.Entry as Entry exposing (Action(..))
import Entries.EntryModel as EntryModel exposing (Id)

-- MODEL

type alias Entry = EntryModel.Model
type alias Cache = Dict Id Entry

type alias Model =
    { displayed : List Id
    , cache : Cache       -- also contains info about whether an item is exapanded
    , message : String
    }

init : Model
init =
    { displayed = [], cache = Dict.empty, message = "" }

-- UPDATE

type Action =
      GetEntryFor Id
    | EntryReceived (Result Http.Error Entry)
    | CloseAll
    | EntryAction Id Entry.Action

update : Action -> Model -> (Model, Effects Action)
update action model =
    case action of
        GetEntryFor id ->
            (model, loadEntry id )
        EntryReceived (Result.Ok entry) ->
            ( { model |
                  displayed <- entry.id :: model.displayed
                , cache <- insert entry.id entry model.cache
              }
            , Effects.none
            )
        EntryReceived (Result.Err msg) ->
            ( { model | message <- errorHandler msg }
            , Effects.none
            )
        CloseAll ->
            ( { model | displayed <- [] }, Effects.none )
        EntryAction id Close ->
            ( { model | displayed <- List.filter (\d -> d /= id) model.displayed }
            -- ( { model | displayed <- take (idx) model.displayed ++ drop (idx+1) model.displayed }
            , Effects.none
            )
        EntryAction id entryAction ->    -- i.e. Expand
            -- update : comparable -> (Maybe Entry -> Maybe Entry) -> Dict comparable Entry -> Dict comparable Entry
            let
                getSetCache : Maybe Entry -> Maybe Entry
                getSetCache mentry =
                    case mentry of
                        Just entry -> Just (Entry.update entryAction entry)
                        Nothing -> Nothing
            in
            ( { model | cache <- Dict.update id getSetCache model.cache }
            , Effects.none
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
        -- viewMapper : Int -> Id -> Html
        -- viewMapper ix id =
        --     let (Just entry) = get id model.cache
        --     in Entry.view (Signal.forwardTo address (EntryAction ix)) entry
    in
    div [ id "entries" ]
        [ h2 [] [ text "Entries" ]
        , button
            [ onClick address CloseAll
            , class "btn btn-default" ]
            [ text "Close All" ]
        , div [ class "eContainer" ]
            -- <| List.indexedMap viewMapper model.displayed
            <| List.map viewMapper model.displayed
            -- <| List.map (\e -> Entry.view (Signal.forwardTo address (EntryAction e.id)) e) model.displayed
        , p [] [ text model.message ]
        ]


-- TASKS

loadEntry : Id -> Effects Action
loadEntry id =
    Http.get entryDecoder ("http://localhost:3000/api/register/id/" ++ id)
        |> Task.toResult
        |> Task.map EntryReceived
        |> Effects.task


-- getSet : Int -> (a -> a) -> Array a -> Array a
-- getSet i f arr =
--     let (Just e) = get i arr
--     in set i (f e)



-- getSetCache : Id -> (Entry -> Entry) -> Cache -> Cache
-- getSetCache id f cache =
--     let (Just entry) = get id cache
--     in set id (f entry)
