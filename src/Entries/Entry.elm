module Entries.Entry (Action(..), update, view) where

import Html exposing (..)
import Html.Attributes exposing (class, id, type', href)
import Html.Events exposing (onClick, on, targetValue)

import Entries.EntryModel exposing (init, Model)

type Action =
      Close
    | Expand

update : Action -> Model -> Model
update action model =
    case action of
        Expand -> { model  | expand <- not model.expand }

view : Signal.Address Action -> Model -> Html
view address entry =
    div [ class "entry" ]
        [ h4 [] [ text entry.orgName ]
        , button
            [ class "btn btn-default btn-xs"
            , onClick address Close
            ] [ text "X" ]
        , viewMeta entry
        , button [ onClick address Expand ] [ text "more..."]
        , viewMore entry
        ]

viewMeta : Model -> Html
viewMeta entry =
    div [ class "row" ]
        [ div [ class "col-sm-3" ]
            [ h4 [] [ text "Country" ]
            , p [] [ text entry.hqCountry ]
            ]
        , div [ class "col-sm-3" ]
            [ h4 [] [ text "Representative" ]
            , p [] [ text entry.euPerson ]
            ]
        , div [ class "col-sm-3" ]
            [ h4 [] [ text "Budget" ]
            , p [] [ text entry.costEst ]
            ]
        , div [ class "col-sm-3" ]
            [ h4 [] [ text "FTEs" ]
            , p [] [ text <| toString entry.noFTEs ]
            ]
        ]

viewMore : Model -> Html
viewMore entry =
    div [ collapse entry.expand ]
        [ div [ class "col-sm-6" ]
            [ h4 [] [ text "Memberships" ]
            , p [] [ text entry.memberships ]
            ]
        , div [ class "col-sm-6" ]
            [ h4 [] [ text "..." ]
            , p [] [ text entry.hqCountry ]
            ]
        ]

collapse : Bool -> Attribute
collapse expand =
    if expand
    then class "row collapse in"
    else class "row collapse"
