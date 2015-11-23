module Entries.Entries (Model, Action(..), init, update, view, updateUrl) where

import Html exposing (..)
import Html.Attributes exposing (class, id, type', href, style)
import Html.Events exposing (onClick, on, targetValue)
import List exposing (take, drop)
import Dict exposing (Dict, insert, get)

import Http
import Effects exposing (Effects)
import Task exposing (..)
import History

import Entries.EntryDecoder as EntryDecoder exposing (Id, Model, entryDecoder)
import Entries.Entry as Entry exposing (Action(..))

-- MODEL

type alias Cache = Dict Id (Entry.Model)

type alias Model =
    { displayed : List Id
    , cache : Cache       -- also contains info about whether an item is expanded
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
    | NoOp (Maybe ())

update : Action -> Model -> (Model, Effects Action)
update action model =
    let
        -- once we have the data (whihc might be immediately if in cache),
        -- add to displayed list and start animation
        insertEntry : String -> (Model, Effects Action)
        insertEntry id =
            let newDisplayed = id :: model.displayed
            in
            ( { model | displayed = newDisplayed }
            , Effects.batch
                [ Effects.map (EntryAction id) (Effects.tick Entry.Tick)    -- Entry animation
                , updateUrl newDisplayed   -- History
                -- , Effects.none
                ]
            )
    in
    case action of
        GetEntryFor id -> --( { model | message = "GetEntryFor " ++ model.message }, Effects.none )
            if List.member id model.displayed then        -- already showing, ignore click
                ( model, Effects.none )
            else if Dict.member id model.cache then            -- cached
                insertEntry id
            else
                ( model, loadEntry id )
        EntryReceived (Result.Ok entry) ->
            let (newModel, newEffects) = insertEntry entry.id
            in
            ( { newModel | cache = insert entry.id (Entry.init entry) newModel.cache, message = entry.id }
            , newEffects
            )
        EntryReceived (Result.Err msg) ->
            ( { model | message = errorHandler msg }
            , Effects.none
            )

        -- C L O S E
        CloseAll ->
            ( { model | displayed = [] }
            , updateUrl []    -- History
            -- , Effects.none
            )
        EntryAction id Close ->
            let
                newDisplayed = List.filter (\d -> d /= id) model.displayed
            in
            ( { model |
                displayed = newDisplayed
              , cache = Dict.update id (Maybe.map (Entry.init << .data)) model.cache -- reset cache entry
              }
            , updateUrl newDisplayed   -- History
            -- , Effects.none
            )

        -- E X P A N D
        EntryAction id entryAction ->    -- i.e. Expand
            ( { model | cache = Dict.update id (Entry.update entryAction |> Maybe.map) model.cache }
            , Effects.none
            )

        -- URL  U P D A T E S
        NoOp _ -> ( model, Effects.none )

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
            let entry = Maybe.withDefault Entry.initEmpty (get id model.cache)
            in Entry.view (Signal.forwardTo address (EntryAction id)) entry
    in
    div [ id "entries", class "col-xs-12 col-sm-8" ]
        [ header []
            [ h2 [] [ text "Summary of Transparency Register entries" ]
            , button
                [ onClick address CloseAll
                , class "btn btn-default btn-xs closeAll" ]
                [ text "Close All" ]
            ]
        -- , p [] [ text <| toString model.message ]
        -- , p [] [ text <| toString model.displayed ]
        , div [ class "eContainer" ]
            <| List.map viewMapper model.displayed
        ]

-- TASKS

loadEntry : Id -> Effects Action
loadEntry id =
    Http.get entryDecoder ("/api/register/id/" ++ id)
        |> Task.toResult
        |> Task.map EntryReceived
        |> Effects.task

updateUrl : List String -> Effects Action
updateUrl displayed =
    combineIds displayed
        |> History.replacePath
        |> Task.toMaybe
        |> Task.map NoOp
        |> Effects.task

-- [x,y,z] --> /x/y/z
combineIds : List String -> String
combineIds lst =
    List.foldl (\l acc -> acc ++ l) "/" (List.intersperse "/" lst)
