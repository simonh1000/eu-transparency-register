module Filters.Filters (Model, Action(..), init, update, view) where

import Html exposing (..)
import Html.Attributes exposing (class, id, type')
import Html.Events exposing (onClick, on, targetValue)
import Http exposing (get)
import Json.Decode as Json exposing ( (:=) )

import Effects exposing (Effects)
import Task exposing (..)

import Filters.Section as Section

-- MODEL

type alias Model =
    { search : String
    , section : String
    }

init : Model
init =
    { search = "", section = "All" }

-- UPDATE

type Action =
      Search String
    | Section String
    | GetMatch Model

update : Action -> Model -> (Model, Effects Action)
update action model =
    case action of
        Search s -> ( { model | search <- s }, Effects.none )
        Section s -> ( { model | section <- s }, Effects.none )
        -- GetMatch s -> ( model, loadData s )
        GetMatch s -> ( model, Effects.none )

-- VIEW

view : Signal.Address Action -> Model -> Html
view address model =
    div [ id "filters", class "row" ]
        [ div [ class "col-xs-12" ]
            [ h1 [ ] [ text "Search criteria" ] ]
        , div [ class "col-sm-3" ]
            [ searchView address model ]
        , div [ class "col-sm-3" ]
            [ sectionView address ]
            -- [ Section.view ]
        , p [] [ text <| filters2String model ]
        ]

-- on : String -> Json.Decode.Decoder Action -> (Action -> Message) -> Attribute
-- Signal.message : Address Action -> (Action -> Message)
-- onClick : Signal.Address Action -> Action -> Attribute
searchView : Signal.Address Action -> Model -> Html
searchView address model =
    div [ class "input-group" ]
        [ input
            [ type' "text"
            , class "form-control"
            , on "input" (Json.map Search targetValue) (Signal.message address)
            ]
            [ text model.search ]
        , span [ class "input-group-btn" ]
            [ button
                [ type' "button"
                , class "btn btn-default"
                , onClick address (GetMatch model)
                ]
                [ text "Go!" ]
            ]
        ]

sectionView : Signal.Address Action -> Html
sectionView address =
    select
        [ class "form-control"
        , on "change" (Json.map Section targetValue) (Signal.message address)
        ]
        <| List.map (option [] << (List.repeat 1) << text) Section.subsections

filters2String : Model -> String
filters2String model =
    ".search: " ++ model.search ++ " .section: " ++ model.section
