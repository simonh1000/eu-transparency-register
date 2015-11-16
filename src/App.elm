module App (Action(UrlParam), init, update, view) where

import Html exposing (..)
import Html.Attributes exposing (class)
import Html.Events exposing (onClick)
import String exposing (split, toLower)
import List exposing (head, tail, filter)

import History
import Task exposing (..)
import Effects exposing (Effects)

import Register exposing (Action(..))
import Nav exposing (Page(..), Action(..))
import Summary.Summary as Summary
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
    ( { page = Register
      , register = fst Register.init
      , summary = Summary.init
      , help = False
      }
    , Effects.none
    )

-- UPDATE

type Action =
    UrlParam String
    | RegisterAction Register.Action
    | NavAction Nav.Action
    | SummaryAction Summary.Action
    | Help
    | NoOp (Maybe ())

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
                    , Effects.map SummaryAction <|
                        snd (Summary.update Summary.Activate model.summary)
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

        -- NavAction (Nav.NoOp _) -> (model, Effects.none)

        NavAction navAction ->
            case Nav.update navAction of
                -- model.page ->
            -- let
            --     newPage = Nav.update navAction
            -- in if | newPage == model.page ->
                        -- (model, Effects.none)
                Summary ->
                --   | newPage == Summary ->
                        let (newModel, newEffects) = Summary.update Summary.Activate model.summary
                        in
                        ( { model | page <- Summary, summary <- newModel }
                        , Effects.map SummaryAction newEffects
                        )
                Recent ->
                    let (newModel, newEffects) =
                        Register.update (Register.UrlParam ["recent"]) model.register
                    in  ( { model |
                            register <- newModel
                            , page <- Register }
                        , Effects.batch
                            [ Effects.map RegisterAction newEffects
                            , updateUrl "recent"
                            ]
                        )
                Register ->
                --   | newPage == Register ->
                      let (newModel, newEffects) =
                          Register.update (Register.UrlParam []) model.register
                      in  ( { model |
                                register <- newModel
                              , page <- Register }
                          , Effects.map RegisterAction newEffects
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

        NoOp _ -> ( model, Effects.none )

-- VIEW

view : Signal.Address Action -> Model -> Html
view address model =
    div [ class <| "container " ++ toString model.page ]
        [ Nav.navbar (Signal.forwardTo address NavAction)
        , helpModal address model
        , if model.page == Summary
            then Summary.view (Signal.forwardTo address SummaryAction) model.summary
            else Register.view (Signal.forwardTo address RegisterAction) model.register
        , helpButton address
        ]

helpButton : Signal.Address Action -> Html
helpButton address =
    footer [ class "row" ]
        [ div [ class "col-xs-12" ]
            [ button
                [ class "btn btn-default btn-xs"
                , onClick address Help
                ] [ text "Notes, privacy, source code or report a problem" ]
            ]
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

updateUrl : String -> Effects Action
updateUrl displayed =
    History.replacePath displayed
        |> Task.toMaybe
        |> Task.map NoOp
        |> Effects.task
