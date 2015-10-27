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

type alias AnimationState =
    Maybe { prevClockTime : Time, elapsedTime: Time }
duration = 0.7 * second
entryheight = 130

type alias Model =
    { data : EntryDecoder.Model
    , expand : Bool
    , entry : Bool
    , animationState: AnimationState
    }

init : EntryDecoder.Model -> Model
init data =
    { data = data
    , expand = False
    , entry = True
    -- , animationState = Nothing
    , animationState = Just { prevClockTime = 0, elapsedTime = 0 }
    }

-- U P D A T E

type Action =
      Enter    -- unused
    | Tick Time
    | Expand
    | Close       -- caught by Entries

update : Action -> Model -> (Model, Effects Action)
update action model =
    case action of
        Tick _ ->
            ( { model | entry <- False }
            , Effects.none                    -- stop Ticks
            )
        Expand -> ( { model  | expand <- not model.expand }, Effects.none )


-- V I E W

view : Signal.Address Action -> Model -> Html
view address model =
    -- div [ class "entry", animationStyles model.animationState ]
    div [ animationStyles model.entry ]
        [ h3 [] [ text model.data.orgName ]
        , button
            [ class "btn btn-default btn-xs closeEntry"
            , onClick address Close
            ] [ text "X" ]
        , viewMeta address model.data
        , button
            [ class "btn btn-default btn-xs expandEntry", onClick address Expand ]
            [ text "v"]
        , viewMore model
        ]

viewMeta : Signal.Address Action -> EntryDecoder.Model -> Html
viewMeta address entry =
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
viewMore model =
    div [ collapse model.expand ]
        [ div [ class "col-sm-6" ]
            [ h4 [] [ text "Memberships" ]
            , p [] [ text model.data.memberships ]
            ]
        , div [ class "col-sm-6" ]
            [ h4 [] [ text "..." ]
            , p [] [ text model.data.hqCountry ]
            ]
        ]


animationValue : Int -> AnimationState -> String
animationValue tgtHeight state =
    case state of
        Nothing -> (toString tgtHeight) ++ "px"
        -- Nothing -> "auto"
        Just { elapsedTime } ->
            (toFloat tgtHeight) * elapsedTime / duration
                |> round
                |> toString
                |> \s -> s ++ "px"

animationStyles : Bool -> Attribute
animationStyles entry =
    if entry then
        class "entry"
    else class "entry expand"
-- animationStyles : AnimationState -> Attribute
-- animationStyles state =
--     style
--         [ ( "height", animationValue entryheight state )
--         , ( "marginBottom", animationValue 10 state )
--         ]


collapse : Bool -> Attribute
collapse expand =
    if expand
    then class "row collapse in"
    else class "row collapse"
