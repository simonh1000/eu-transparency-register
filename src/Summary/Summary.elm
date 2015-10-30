module Summary.Summary (Model, Action(..), init, update, view) where

import Html exposing (..)
import Html.Attributes exposing (class, id, style)
import Html.Events exposing (onClick, on, targetValue)

import Json.Decode exposing (Decoder, list, (:=), string, int, object2)

import Http
import Effects exposing (Effects)
import Task

import Chart.Chart exposing (..)

-- MODEL

type alias Summary =
    { interest: String
    , count: Int
    }

type alias Model = List Summary

initSummary i c =
    { interest = i
    , count = c
    }

init = ( [], loadData )

-- UPDATE
type Action =
      Activate
    | SummaryData (Result Http.Error Model)

update : Action -> Model -> (Model, Effects Action)
update action model =
    case action of
        Activate ->
            (model, loadData)
        SummaryData (Result.Ok model) ->
            ( model, Effects.none)

-- VIEW

view : Signal.Address Action -> Model -> Html
view address model =
    let sorted = List.sortBy ( (\x -> -x) << .count) model
    in
    chart
        (List.map (toFloat << .count) sorted)
        (List.map .interest sorted)
        "Number of registrants expressing interest in subject"

-- TASKS

loadData : Effects Action
loadData =
    Http.get summaryDecoder ("/api/register/interests")
        |> Task.toResult
        |> Task.map SummaryData
        |> Effects.task

summaryDecoder : Decoder Model
summaryDecoder =
    object2
        initSummary
        ("issue" := string)
        ("count" := int)
    |> list
