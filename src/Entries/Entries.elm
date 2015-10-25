module Entries.Entries (Model, Action(..), init, update, view) where

import Html exposing (..)
import Html.Attributes exposing (class, id, type', href)
import Html.Events exposing (onClick, on, targetValue)
import Http exposing (get)

import Effects exposing (Effects)
import Task exposing (..)

import Entries.EntryDecoder as EntryDecoder exposing (Id, entryDecoder)

-- MODEL

type alias Entry = EntryDecoder.Model

type alias Model =
    { entries : List Entry
    , message : String
    }

init : Model
init =
    { entries = [], message = "" }

type Action =
      GetEntryFor Id
    | EntryReceived (Result Http.Error Entry)

update : Action -> Model -> (Model, Effects Action)
update action model =
    case action of
        GetEntryFor id ->
            (model, loadEntry id )
        EntryReceived (Result.Ok entry) ->
            ( { model | entries <- entry :: model.entries }
            , Effects.none
            )
        EntryReceived (Result.Err msg) ->
            ( { model | message <- "Entry download error" }
            , Effects.none
            )

view : Signal.Address Action -> Model -> Html
view address model =
    div [ id "entries" ]
        [ div []
            [ h2 [] [ text "Entries" ]
            , div [ class "eContainer" ] <| List.map (viewEntry address) model.entries
            ]
        , p [] [ text model.message ]
        ]

viewEntry : Signal.Address Action -> Entry -> Html
viewEntry address entry =
    div [ class "entry" ]
        [ p [] [ text entry ] ]


-- TASKS
loadEntry : Id -> Effects Action
loadEntry id =
    Http.get entryDecoder ("http://localhost:3000/api/register/id/" ++ id)
        |> Task.toResult
        |> Task.map EntryReceived
        |> Effects.task
