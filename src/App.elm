module App (Action(UrlParam), init, update, view) where

import Html exposing (..)
import Html.Attributes exposing (class)
import Html.Events exposing (onClick)
import String exposing (split, toLower)
import List exposing (head, tail, filter)

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
    , register : Register.Model
    , summary : Summary.Model
    , help : Bool
    , msg : String
    }

init : (Model, Effects Action)
init =
    ( { navbar = Nav.init Register ""
    --   , page = Register
      , register = fst Register.init
      , summary = Summary.init
      , help = False
      , msg = ""
      }
    , getMeta
    )

-- UPDATE

type Action
    = UrlParam String
    | NavAction Nav.Action
    | SummaryAction Summary.Action
    | RegisterAction Register.Action
    | MetaReceived (Result Http.Error String)
    | Help
    -- | NoOp (Maybe ())

update : Action -> Model -> (Model, Effects Action)
update action model =
    let
        switchSummary =
            let
                navModel = Nav.update GoSummary model.navbar
                (_, sumEffects) = Summary.update Summary.Activate model.summary
            in  ( { model | navbar = navModel }
                , Effects.map SummaryAction sumEffects    -- download data, update url
                )
        switchRegister params =
            let
                navModel = Nav.update (GoRegister params) model.navbar   -- set page in model
                (newModel, newEffects) =
                    Register.update (Register.Activate params) model.register
            in
                ( { model
                    | navbar = navModel
                    , register = newModel }
                , Effects.map RegisterAction newEffects
                )
    in
    case action of
         -- download data (if necessary), switch view
        UrlParam str -> -- (model, Effects.none)
            let
                urlElems = filter ((/=) "") (split "/" str)
            in
            case head urlElems of
                Just "summary" ->  switchSummary
                otherwise -> switchRegister urlElems
                -- Just _ ->
                --     let (newModel, newEffects) =
                --         Register.update (Register.UrlParam urlElems) model.register
                --     in  ( { model |
                --               register = newModel
                --             , navbar = Nav.update GoRegister model.navbar }
                --         , Effects.map RegisterAction newEffects
                --         )
                -- Nothing ->
                --     ( { model | navbar = Nav.update GoRegister model.navbar }
                --     , Effects.none
                --     )
        -- update URL, download data (if necessary), switch view (change page model)
        NavAction navAction ->
            -- let tmpModel = { model | navbar = Nav.update navAction model.navbar }
            -- in
            case navAction of
                GoSummary -> switchSummary
                GoRegister params -> switchRegister params
                CountData _ -> (model, Effects.none)   -- ************
                -- GoRecent ->
                --     let (newModel, newEffects) =
                --         Register.update (Register.UrlParam ["recent"]) model.register
                --     in  ( { tmpModel | register = newModel }
                --         , Effects.batch
                --             [ Effects.map RegisterAction newEffects
                --             , updateUrl "recent"
                --             ]
                --         )
                -- GoRegister ->
                --     let (newModel, newEffects) =
                --         Register.update (Register.UrlParam []) model.register
                --     in  ( { tmpModel | register = newModel }
                --         , Effects.map RegisterAction newEffects
                --         )


        RegisterAction regAction ->
            let (newModel, newEffects) = Register.update regAction model.register
            in  ( { model | register = newModel }
                , Effects.map RegisterAction newEffects
                )

        SummaryAction summaryAction ->
            let (newModel, newEffects) = Summary.update summaryAction model.summary
            in  ( { model | summary = newModel }
                , Effects.map SummaryAction newEffects
                )

        MetaReceived (Result.Ok val)->     -- ***** this should be nav downloading this data
            ( { model | navbar = Nav.update (Nav.CountData val) model.navbar }
            , Effects.none
            )
        MetaReceived (Result.Err err)->
            ( { model | msg = Common.errorHandler err }
            , Effects.none
            )

        Help ->
            ( { model | help = not model.help }
            , Effects.none
            )

        -- NoOp _ -> ( model, Effects.none )

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
