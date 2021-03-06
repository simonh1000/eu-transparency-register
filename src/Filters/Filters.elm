module Filters.Filters (Model, Action(..), init, update, view) where

import Html exposing (..)
import Html.Attributes as Attr exposing (class, id, type')
import Html.Events exposing (onClick, onSubmit, on, onWithOptions, targetValue)

import Json.Decode as Json

import Filters.Section as Section

-- MODEL

type alias Model =
    { search : String
    , section : String
    , country : String
    , fte: String
    , budget: String
    }

init : Model
init =
    { search = ""
    , section = "All"
    , country = "All"
    , fte = "0"
    , budget = "0"
    }

-- UPDATE

type Action =
      Search String
    | Section String
    | Country String
    | FTE String
    | Budget String
    | GetMatch Model     -- caugth by App

update : Action -> Model -> Model
update action model =
    case action of
        Search s  -> { model | search = s }
        Section s -> { model | section = s }
        Country s -> { model | country = s }
        FTE s     -> { model | fte = s }
        Budget s  -> { model | budget = s }
        GetMatch _ -> model

-- VIEW

view : Signal.Address Action -> Model -> Html
view address model =
    let
        onSubmitSPA address' act =
            onWithOptions
                "submit"
                {stopPropagation=True, preventDefault=True}
                (Json.succeed act)
                (Signal.message address')
    in
    form
        [ id "filters"
        , class "col-xs-12"
        , onSubmitSPA address (GetMatch model)
        ]
        [ div [class "row" ]
            [ div [ class "col-xs-6 col-sm-3" ]
                [ searchView address model ]
            , div [ class "col-xs-6 col-sm-3" ]
                -- [ sectionView address ]
                [ countryView address ]
            , div [ class "col-xs-6 col-sm-3" ]
                [ fteView address model.fte ]
            , div [ class "col-xs-6 col-sm-3" ]
                [ budgetView address model.budget ]
            ]
        , div [class "row searchInit" ]
            [ div [ class "col-xs-6 col-xs-offset-6 col-sm-3 col-sm-offset-9" ]
                [ button
                    [ class "btn btn-primary"
                    , type' "submit"
                    -- , onClick address (GetMatch model)
                    ] [ text "Search!" ]
                ]
            ]
        ]

searchView : Signal.Address Action -> Model -> Html
searchView address model =
    div [ class "box" ]
        [ h4 []
            [ text "Search"
            , span [ class "hidden-xs" ] [ text " by name" ]
            ]
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
            ] <|
            List.map (option [] << (List.repeat 1) << text) Section.subsections
        ]

countryView : Signal.Address Action -> Html
countryView address =
    div []
        [ h4 [] [ text "HQ Country" ]
        , select
            [ class "form-control"
            , on "change" (Json.map Country targetValue) (Signal.message address)
            ] <|
            List.map (\c -> option [] [ text c ]) Section.countries
        ]

fteView : Signal.Address Action -> String -> Html
fteView address val =
    div []
        [ h4 []
            [ text "Staff"
            , span [ class "small" ] [ text <| " (at least " ++ val ++ " FTEs)" ]
            ]
        , input
            [ type' "range"
            , Attr.min "0"
            , Attr.max "40"
            , Attr.step "2"
            , Attr.value val
            , on "change" (Json.map FTE targetValue) (Signal.message address)
            ] []
        ]

budgetView : Signal.Address Action -> String -> Html
budgetView address val =
    div []
        [ h4 []
            [ text "Budget"
            , span [ class "small" ] [ text <| " (at least €" ++ val ++ ")" ]
            ]
        , input
            [ type' "range"
            , Attr.min "0"
            , Attr.max "10000000"
            , Attr.step "500000"
            , Attr.value val
            , on "change" (Json.map Budget targetValue) (Signal.message address)
            ] []
        ]

-- submitRow : Signal.Address Action -> Model -> Html
-- submitRow address model =
--     div [ class "row" ]
--         [ div [ class "col-sm-3" ]
--             [ button
--                 [ type' "button"
--                 , class "btn btn-default"
--                 , onClick address (GetMatch model)
--                 ]
--                 [ text "Search!" ]
--             ]
--         , div [ class "col-sm-3" ]
--             [ p [] [ text (filters2String model) ] ]
--         ]
--
-- filters2String : Model -> String
-- filters2String model =
--     ".search: " ++ model.search ++
--     " .section: " ++ model.section ++
--     " .fte: " ++ model.fte
