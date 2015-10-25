module Filters.Filters (Model, Action(..), init, update, view) where

import Html exposing (..)
import Html.Attributes exposing (class, id, type')
import Html.Events exposing (onClick, on, targetValue)
import Http exposing (get)
import Json.Decode as Json exposing ( (:=) )

import Effects exposing (Effects)
import Task exposing (..)

-- MODEL

type alias Model =
    { search : String
    }

init : Model
init =
    { search = "" }

-- UPDATE

type Action =
      Search String
    | GetMatch String

update : Action -> Model -> (Model, Effects Action)
update action model =
    case action of
        Search s -> ( { model | search <- s }, Effects.none )
        -- GetMatch s -> ( model, loadData s )
        GetMatch s -> ( model, Effects.none )

-- VIEW

view : Signal.Address Action -> Model -> Html
view address model =
    div [ id "filters", class "row" ]
        [ div [ class "col-xs-12" ]
            [ h1 [ ] [ text "Search criteria" ] ]
        , div [ class "col-sm-3" ]
            [ input
                [ type' "text"
                -- on : String -> Json.Decode.Decoder Action -> (Action -> Message) -> Attribute
                -- Signal.message : Address Action -> (Action -> Message)
                , on "input" (Json.map Search targetValue) (Signal.message address)
                ] [ text model.search ]
                -- onClick : Signal.Address Action -> Action -> Attribute
            , button [ type' "button", onClick address (GetMatch model.search) ] [ text "Go!" ]
            ]
        ]
