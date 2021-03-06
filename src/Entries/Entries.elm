module Entries.Entries (Model, Action(..), init, update, view) where

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
import Common exposing (errorHandler)

-- MODEL

type alias Cache = Dict Id (Entry.Model)

type alias Model =
    { displayed : List Id
    , cache : Cache       -- also contains info about whether an item is expanded
    , message : Maybe String
    , loading : Bool
    }

init : Model
init =
    Model [] Dict.empty Nothing False

-- UPDATE

type Action
    = GetEntryFor Id
    | EntryReceived (Result Http.Error EntryDecoder.Model)  -- Decoder brings in raw data
    | Reset
    | EntryAction Id Entry.Action

update : Action -> Model -> (Model, Effects Action)
update action model =
    let
        -- once we have the data (which might be immediately if in cache),
        -- add to displayed list and start animation
        insertEntry : String -> (Model, Effects Action)
        insertEntry id =
            let newDisplayed = id :: model.displayed
            in
            ( { model | displayed = newDisplayed }
            -- , Effects.none
            , Effects.map (EntryAction id) (Effects.tick Entry.Tick)
            )
    in
    case action of
        GetEntryFor id -> --( { model | message = "GetEntryFor " ++ model.message }, Effects.none )
            if List.member id model.displayed then        -- already showing, ignore click
                ( model, Effects.none )
            else if Dict.member id model.cache then            -- cached
                insertEntry id
            else
                ( { model | loading = True }
                , loadEntry id
                )
        EntryReceived (Result.Ok entry) ->
            let (newModel, newEffects) = insertEntry entry.id
            in
            ( { newModel
                | cache = insert entry.id (Entry.init entry) newModel.cache
                , loading = False
               }
            , newEffects
            )
        EntryReceived (Result.Err msg) ->
            ( { model
              | message = Just (errorHandler msg)
              , loading = False
              }
            , Effects.none
            )

        -- C L O S E
        Reset ->
            ( { model | displayed = [], message = Nothing }
            , Effects.none
            )

        EntryAction id Close ->
            let
                newDisplayed = List.filter (\d -> d /= id) model.displayed
            in
            ( { model |
                displayed = newDisplayed
              , cache = Dict.update id (Maybe.map (Entry.init << .data)) model.cache -- reset cache entry
              }
            , Effects.none
            )

        -- E X P A N D
        EntryAction id entryAction ->    -- Expand or Animation Tick
            ( { model
                -- ?? updates either entry or expand in cache ??
                | cache = Dict.update id (Maybe.map <| Entry.update entryAction) model.cache }
            , Effects.none
            )

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
                [ onClick address Reset
                , class "btn btn-default btn-xs closeAll" ]
                [ text "Close All" ]
            ]
        , case model.message of
            Just m -> p [] [ text m ]
            Nothing -> p [] []
        , p [] [ text <| if model.loading then "Loading..." else "" ]
        , div [ class "mainContainer" ] <|
            List.map viewMapper model.displayed
        ]

-- TASKS

loadEntry : Id -> Effects Action
loadEntry id =
    Http.get entryDecoder ("/api/register/id/" ++ id)
        |> Task.toResult
        |> Task.map EntryReceived
        |> Effects.task
