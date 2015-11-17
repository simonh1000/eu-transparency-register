module App (Action(UrlParam), init, update, view) where

import Html exposing (..)
import Html.Attributes exposing (class)
import Html.Events exposing (onClick)
import String exposing (split, toLower)
import List exposing (head, tail, filter)

import History
import Http
import Json.Decode as Json exposing ( (:=) )
import Task exposing (Task)
import Effects exposing (Effects)

import Register exposing (Action(..))
import Nav exposing (Page(..), Action(..))
import Summary.Summary as Summary
import Help
import Common

-- MODEL

type alias Model =
    { navbar : Nav.Model
    -- , page : Nav.Page
    -- , regCount : String
    , register : Register.Model
    , summary : Summary.Model
    , help : Bool
    , msg : String
    }

init : (Model, Effects Action)
init =
    ( { navbar = Nav.init Register ""
    --   , page = Register
    --   , regCount = ""
      , register = fst Register.init
      , summary = Summary.init
      , help = False
      , msg = ""
      }
    , getMeta
    )

-- UPDATE

type Action =
    UrlParam String
    | MetaReceived (Result Http.Error String)
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
                    ( { model | navbar <- Nav.update GoSummary model.navbar }
                    , Effects.map SummaryAction <|
                        snd (Summary.update Summary.Activate model.summary)
                    )
                Just _ ->
                    let (newModel, newEffects) =
                        Register.update (Register.UrlParam urlElems) model.register
                    in  ( { model |
                              register <- newModel
                            , navbar <- Nav.update GoRegister model.navbar }
                        , Effects.map RegisterAction newEffects
                        )
                Nothing ->
                    ( { model | navbar <- Nav.update GoRegister model.navbar }
                    , Effects.none
                    )

        MetaReceived (Result.Ok val)->
            ( { model | navbar <- Nav.update (Nav.CountData val) model.navbar }
            , Effects.none
            )
        MetaReceived (Result.Err err)->
            ( { model | msg <- Common.errorHandler err }
            , Effects.none
            )

        -- NavAction (Nav.NoOp _) -> (model, Effects.none)
        NavAction navAction ->
            let tmpModel = { model | navbar <- Nav.update navAction model.navbar }
            in
            case navAction of
                GoSummary ->
                    let (newModel, newEffects) = Summary.update Summary.Activate model.summary
                    in
                        ( { tmpModel | summary <- newModel }
                        , Effects.map SummaryAction newEffects
                        )
                GoRecent ->
                    let (newModel, newEffects) =
                        Register.update (Register.UrlParam ["recent"]) model.register
                    in  ( { tmpModel | register <- newModel }
                        , Effects.batch
                            [ Effects.map RegisterAction newEffects
                            , updateUrl "recent"
                            ]
                        )
                GoRegister ->
                    let (newModel, newEffects) =
                        Register.update (Register.UrlParam []) model.register
                    in  ( { tmpModel | register <- newModel }
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
    div [ class <| "App " ++ toString model.navbar.page ]
        [ Nav.view (Signal.forwardTo address NavAction) model.navbar
        , div [ class "container" ]
            [ helpModal address model
            , if model.navbar.page == Summary
                then Summary.view (Signal.forwardTo address SummaryAction) model.summary
                else Register.view (Signal.forwardTo address RegisterAction) model.register
            , footerDiv address
            , div [] [ text model.msg ]
            ]
        ]

footerDiv : Signal.Address Action -> Html
footerDiv address =
    footer [ class "row" ]
        [ div [ class "col-xs-12" ]
            [ span
                [ ] [ text "Simon Hampton, 2015" ]
            , button
                [ class "btn btn-default btn-xs"
                , onClick address Help
                ]
                [ text "Notes, privacy, source code or report a problem" ]
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

-- TASKS
getMeta : Effects Action
getMeta =
    Http.get (Json.map toString ("count" := Json.int)) ("/api/register/meta")
        |> Task.toResult
        |> Task.map MetaReceived
        |> Effects.task


updateUrl : String -> Effects Action
updateUrl displayed =
    History.replacePath displayed
        |> Task.toMaybe
        |> Task.map NoOp
        |> Effects.task
