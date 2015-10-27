module Filters.Filters (Model, Action(..), init, update, view) where

import Html exposing (..)
import Html.Attributes as Attr exposing (class, id, type')
import Html.Events exposing (onClick, on, targetValue)

-- import Http exposing (get)
import Json.Decode as Json

import Effects exposing (Effects)
import Task exposing (..)

import Filters.Section as Section

-- MODEL

type alias Model =
    { search : String
    , section : String
    , fte: String
    }

init : Model
init =
    { search = "", section = "All", fte = "0" }

-- UPDATE

type Action =
      Search String
    | Section String
    | FTE String
    | GetMatch Model

update : Action -> Model -> (Model, Effects Action)
update action model =
    case action of
        Search s -> ( { model | search <- s }, Effects.none )
        Section s -> ( { model | section <- s }, Effects.none )
        FTE s -> ( { model | fte <- s }, Effects.none )
        GetMatch s -> ( model, Effects.none )

-- VIEW

view : Signal.Address Action -> Model -> Html
view address model =
    div [ id "filters" ]
        [ div [ class "row" ]
            [ div [ class "col-xs-6" ]
                [ h2 [ ] [ text "Criteria selection" ] ]
            , div [ class "col-sm-3 col-sm-offset-3 searchInit" ]
                [ button
                    [ type' "button"
                    , class "btn btn-primary"
                    , onClick address (GetMatch model)
                    ]
                    [ text "Search!" ]
                ]
            ]
        , div [ class "row" ]
            [ div [ class "col-sm-3" ]
                [ searchView address model ]
            , div [ class "col-sm-3" ]
                [ sectionView address ]
            , div [ class "col-sm-3" ]
                [ fteView address model.fte ]
            , div [ class "col-sm-3" ]
                [ p [] [ ] ]
            ]
        -- , submitRow address model
        ]

-- on : String -> Json.Decode.Decoder Action -> (Action -> Message) -> Attribute
-- Signal.message : Address Action -> (Action -> Message)
-- onClick : Signal.Address Action -> Action -> Attribute
searchView : Signal.Address Action -> Model -> Html
searchView address model =
    div [  ]
        [ h4 [] [ text "Search" ]
        , input
            [ type' "text"
            , class "form-control"
            , on "input" (Json.map Search targetValue) (Signal.message address)
            ]
            [ text model.search ]
        ]

sectionView : Signal.Address Action -> Html
sectionView address =
    div []
        [ h4 [] [ text "Type of org" ]
        , select
            [ class "form-control"
            , on "change" (Json.map Section targetValue) (Signal.message address)
            ]
            <| List.map (option [] << (List.repeat 1) << text) Section.subsections
        ]

fteView : Signal.Address Action -> String -> Html
fteView address val =
    div []
        [ h4 [] [ text <| "FTE (at least " ++ val ++ ")" ]
        , input
            [ type' "range"
            , Attr.min "0"
            , Attr.max "20"
            , Attr.step "2"
            , Attr.value val
            , on "change" (Json.map FTE targetValue) (Signal.message address)
            ] [ text "6"]
        ]

submitRow : Signal.Address Action -> Model -> Html
submitRow address model =
    div [ class "row" ]
        [ div [ class "col-sm-3" ]
            [ button
                [ type' "button"
                , class "btn btn-default"
                , onClick address (GetMatch model)
                ]
                [ text "Search!" ]
            ]
        , div [ class "col-sm-3" ]
            [ p [] [ text (filters2String model) ] ]
        ]

filters2String : Model -> String
filters2String model =
    ".search: " ++ model.search ++
    " .section: " ++ model.section ++
    " .fte: " ++ model.fte
