module App (Action(..), init, update, view) where

import Html exposing (..)
import Html.Attributes exposing (class, id)
import Html.Events exposing (onClick)
import String exposing (split, toLower)
import List exposing (head, tail, filter)
import Effects exposing (Effects)

import Register exposing (Action(..))
import Nav exposing (Action(..))
import Router exposing (Page(..), toString)
import Summary.Summary as Summary
import Help exposing (Action(Help))
import Comments.Comments as Comments
import Common exposing (onLinkClick)

-- MODEL

type alias Model =
    { navbar : Nav.Model
    , page : Router.Page
    , register : Register.Model
    , summary : Summary.Model
    , help : Help.Model
    , comments : Comments.Model
    , msg : String
    }
-- initModel n r s =
--     Model n (Register Nothing) r s Help.init Comments.init "" False

init : (Model, Effects Action)
init =
    let
        (navM, navE) = Nav.init
        (regM, regE) = Register.init
        (comM, comE) = Comments.init
    in  ( Model
            navM
            (Register Nothing)
            regM
            Summary.init
            Help.init
            comM
            ""
        -- initModel (fst nav) (fst reg) Summary.init
        , Effects.batch
            [ Effects.map NavAction navE
            , Effects.map RegisterAction regE
            , Effects.map CommentsAction comE
            ]
        )

-- UPDATE

type Action
    = UrlParam String
    -- | Width Int
    | RouterAction Router.Action
    | NavAction Nav.Action
    | SummaryAction Summary.Action
    | RegisterAction Register.Action
    | CommentsAction Comments.Action

{-
On load
    UrlParams passed to Router, giving back page (and [IDs])
    then to switchPage, which passes to Register.update (tagged Activate)
        - Each ID passed to Entries.update (GetMatchFor)
            - loadEntry

-}

update : Action -> Model -> (Model, Effects Action)
update action model =
    let
        switchPage page otherEffects =
            let newModel =
                { model | page = page }
            in
            case page of
                Summary ->
                    ( newModel
                    , Effects.batch
                        [ Summary.update Summary.Activate model.summary
                            |> snd
                            |> Effects.map SummaryAction
                        , otherEffects
                        ]
                    )
                Register params ->
                    let (newRegModel, newEffects) =
                        Register.update (Register.Activate params) model.register
                    in ( { newModel | register = newRegModel }
                       , Effects.batch
                            [ Effects.map RegisterAction newEffects
                            , otherEffects
                            ]
                       )
    in
    case action of
        UrlParam str ->
            let
                (page, routerEffects) =
                    Router.update (Router.UrlParams str)
            in switchPage page (Effects.map RouterAction routerEffects)

        NavAction navAction ->
            case navAction of
                Nav.Reset ->
                    ( { model
                      | register = fst <| Register.update Register.Reset model.register
                      , page = Router.Register Nothing
                      }
                    --   update Url to '/'
                    , Effects.map RouterAction (snd <| Router.update <| Router.NavAction (Register Nothing))
                    )
                GoPage navPage ->
                    let (page, routerEffects) =
                        Router.update <| Router.NavAction <|
                            if navPage == Register Nothing
                            -- Set Url with any displayed entries
                            then Register (Just model.register.entries.displayed)
                            else navPage                        -- Navbar: recents
                    in switchPage page (Effects.map RouterAction routerEffects)

                CountData x ->
                    ( { model | navbar = Nav.update (CountData x) model.navbar }
                    , Effects.none
                    )

        RegisterAction regAction ->
            let
                (newModel, newEffects) =
                    Register.update regAction model.register

                routerEffects =
                    case regAction of
                        Register.EntriesAction _ ->     -- updateURL everytime
                            Router.update (Router.NavAction <| Register (Just newModel.entries.displayed))
                                |> snd
                        otherwise -> Effects.none
            in  ( { model | register = newModel }
                , Effects.batch
                    [ Effects.map RegisterAction newEffects
                    , Effects.map RouterAction routerEffects
                    ]
                )

        SummaryAction summaryAction ->
            let (newModel, newEffects) = Summary.update summaryAction model.summary
            in  ( { model | summary = newModel }
                , Effects.map SummaryAction newEffects
                )

        RouterAction _ ->     -- NoOp _ in practise
            (model, Effects.none)

        CommentsAction act ->
            let (newModel, newEffects) = Comments.update act model.comments
            in  ( { model | comments = newModel }
                , Effects.map CommentsAction newEffects
                )
        -- Width w ->
        --     ( model
        --     -- ( { model | msg = toString w }
        --     , Effects.none
        --     )

-- VIEW

view : Signal.Address Action -> Model -> Html
view address model =
    div [ class <| "App " ++ Router.toString model.page ]
        [ Nav.view (Signal.forwardTo address NavAction) model.navbar
        -- , Help.view (Signal.forwardTo address Intro) model.help
        , div [ class "container appContainer" ]
            -- [ helpModal address model
            [ if model.comments.displayed
                then Comments.view (Signal.forwardTo address CommentsAction) model.comments
                else div [] []
            , if model.page == Summary
                then Summary.view (Signal.forwardTo address SummaryAction) model.summary
                else Register.view (Signal.forwardTo address RegisterAction) model.register
            , footerDiv address model.msg
            ]
        ]

footerDiv : Signal.Address Action -> String -> Html
footerDiv address msg =
    footer [ class "row" ]
        [ div [ class "col-xs-12" ]
            [ span
                [ ] [ text "Simon Hampton, 2015" ]
            , span [] [ text msg ]
            , button
                [ onClick address (CommentsAction Comments.Display)
                , class "btn btn-warning btn-sm" ]
                [ text "Reactions / comments" ]
            ]
        ]

-- helpModal : Signal.Address Action -> Model -> Html
-- helpModal address model =
--     if model.help
--         then div [ class "help-modal" ]
--             [ Help.content
--             , button
--                 [ class "btn btn-default"
--                 ,  onClick address Help
--                 ]
--                 [ text "Close" ]
--             ]
--         else div [] []
