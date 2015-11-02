module App (Action(UrlParam), init, update, view) where

import Html exposing (..)
import Html.Attributes exposing (class)
import Html.Events exposing (onClick)
import String exposing (split)
import List exposing (head, tail, filter)

import Effects exposing (Effects)

import Register exposing (Action(..))
import Nav exposing (Page(..))
import Summary.Summary as Summary exposing (Action(..))
import Help

-- MODEL

type alias Model =
    { page : Page
    , register : Register.Model
    , summary : Summary.Model
    , help    : Bool
    }

init : (Model, Effects Action)
init =
    ( { page = Summary
      , register = fst Register.init
      , summary = fst Summary.init
      , help = False
      }
    , Effects.map SummaryAction (snd Summary.init)
    )

-- UPDATE

type Action =
    UrlParam String
    | RegisterAction Register.Action
    | NavAction Nav.Action
    | SummaryAction Summary.Action
    | Help

update : Action -> Model -> (Model, Effects Action)
update action model =
    case action of
        UrlParam str -> -- (model, Effects.none)
            let
                urlElems = filter ((/=) "") (split "/" str)
            in
            case head urlElems of
                Just "summary" ->
                    ( { model | page <- Summary }
                    , Effects.map SummaryAction (snd Summary.init)
                    )
                Just _ ->
                    let (newModel, newEffects) =
                        Register.update (Register.UrlParam urlElems) model.register
                    in  ( { model |
                              register <- newModel
                            , page <- Register }
                        , Effects.map RegisterAction newEffects
                        )
                Nothing ->
                    ( { model | page <- Register }
                    , Effects.none
                    )

        NavAction navAction ->
            ( { model | page <- Nav.update navAction }
            , Effects.none   -- *************************
            )

        RegisterAction regAction ->
            let (newModel, newEffects) = Register.update regAction model.register
            in  ( { model | register <- newModel }
                , Effects.map RegisterAction newEffects
                )

        SummaryAction summaryAction ->
            let (newModel, newEffects) = Summary.update summaryAction model.summary
            in  ( { model | summary <- newModel }
                , Effects.map SummaryAction newEffects
                )

        Help ->
            ( { model | help <- not model.help }
            , Effects.none
            )

-- VIEW

view : Signal.Address Action -> Model -> Html
view address model =
    div [ class "container" ]
        [ Nav.navbar (Signal.forwardTo address NavAction)
        , helpModal address model
        , if model.page == Summary
            then Summary.view (Signal.forwardTo address SummaryAction) model.summary
            else Register.view (Signal.forwardTo address RegisterAction) model.register
        , helpButton address
        ]

helpButton : Signal.Address Action -> Html
helpButton address =
    footer []
        [ button
            [ class "btn btn-default btn-xs"
            , onClick address Help
            ] [ text "Notes, privacy, source code or report a problem" ]
        ]

helpModal : Signal.Address Action -> Model -> Html
helpModal address model =
    if model.help
        then div [ class "help-modal" ]
            [ Help.content
            , button
                [ class "btn btn-default"
                ,  onClick address Help
                ] [ text "Close" ]
            ]
        else div [] []
