module App (init, update, view) where

import Html exposing (..)
import Http exposing (get)
import Json.Decode as Json exposing ( (:=) )

import Effects exposing (Effects)
import Task exposing (..)

-- MODEL

type alias Model = String

init : (Model, Effects Action)
init = ("Loading", loadData)

-- UPDATE

type Action =
      Data (Maybe String)

update : Action -> Model -> (Model, Effects Action)
update action model =
    case action of
        Data (Just str) -> (str, Effects.none)
        Data Nothing -> ("Download error", Effects.none)
        otherwise -> (model, Effects.none)

-- VIEW

view : Signal.Address Action -> Model -> Html
view address model =
    div []
        [ h1 [ ] [ text model] ]

-- TASKS
loadData : Effects Action
loadData =
    Http.get ("data" := Json.string) "http://localhost:3000/api/default"
        |> Task.toMaybe
        |> Task.map Data
        |> Effects.task
