module Entries.Entry (Model, Action(..), init, update, view) where

import Html exposing (..)
import Html.Attributes exposing (class, id, type', href, style)
import Html.Events exposing (onClick, on, targetValue)

-- Animation
import Time exposing (Time, second)
import Effects exposing (Effects)
import Task exposing (..)

import Entries.EntryDecoder as EntryDecoder

-- M O D E L

type alias Model =
    { data : EntryDecoder.Model
    , expand : Bool
    , entry : Bool
    }

init : EntryDecoder.Model -> Model
init data =
    { data = data
    , expand = False
    , entry = True
    }

-- U P D A T E

type Action =
      Tick Time
    | Expand
    | Close       -- caught by Entries

update : Action -> Model -> Model
update action model =
    case action of
        Tick _ -> { model | entry <- False }
        Expand -> { model | expand <- not model.expand }

-- V I E W

view : Signal.Address Action -> Model -> Html
view address model =
    -- div [ class "entry", animationStyles model.animationState ]
    div [ animationStyles model.entry ]
        [ div [ ]
            [ h3 [] [ text model.data.orgName ]
            , button
                [ class "btn btn-default btn-xs closeEntry"
                , onClick address Close
                ] [ text "X" ]
            , viewMeta address model.data
            , button
            -- Need to add data-toggle="collapse"
                [ class "btn btn-default btn-xs expandEntry", onClick address Expand ]
                [ text "v"]
            , viewMore model
            ]
        ]

viewMeta : Signal.Address Action -> EntryDecoder.Model -> Html
viewMeta address entry =
    div [ class "row" ]
        [ div [ class "col-xs-6 col-sm-3" ]
            [ h4 [] [ text "Country" ]
            , p [] [ text entry.hqCountry ]
            ]
        , div [ class "col-xs-6 col-sm-3" ]
            [ h4 [] [ text "Representative" ]
            , p [] [ text entry.euPerson ]
            ]
        , div [ class "col-xs-6 col-sm-3" ]
            [ h4 [] [ text "Budget" ]
            , p [] [ text entry.costEst ]
            ]
        , div [ class "col-xs-6 col-sm-3" ]
            [ h4 [] [ text "FTEs" ]
            , p [] [ text <| toString entry.noFTEs ]
            ]
        ]

viewMore : Model -> Html
viewMore model =
    div [ collapse model.expand ]
        [ div [ class "col-sm-6" ]
            [ h4 [] [ text "Goal" ]
            , p [] [ text model.data.goals ]
            ]
        , div [ class "col-sm-6" ]
            [ h4 [] [ text "Memberships" ]
            , p [] [ text model.data.memberships ]
            ]
        ]


animationStyles : Bool -> Attribute
animationStyles entry =
    if entry then
        class "entry"
    else class "entry expand"

collapse : Bool -> Attribute
collapse expand =
    if expand
    then class "row collapse in"
    else class "row collapse"

-- animationStyles : AnimationState -> Attribute
-- animationStyles state =
--     style
--         [ ( "height", animationValue entryheight state )
--         , ( "marginBottom", animationValue 10 state )
--         ]

-- animationValue : Int -> AnimationState -> String
-- animationValue tgtHeight state =
--     case state of
--         Nothing -> (toString tgtHeight) ++ "px"
--         -- Nothing -> "auto"
--         Just { elapsedTime } ->
--             (toFloat tgtHeight) * elapsedTime / duration
--                 |> round
--                 |> toString
--                 |> \s -> s ++ "px"
--
