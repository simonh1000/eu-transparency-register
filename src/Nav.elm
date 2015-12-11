module Nav (Model, Action(..), init, update, view) where

import Html exposing (..)
import Html.Attributes as Attr exposing (..)
import Html.Events exposing (onClick, onWithOptions)

import Http
import Json.Decode as Json exposing ( (:=) )
import Task exposing (Task)
import Effects exposing (Effects)

import Common exposing (onLinkClick)
import Router exposing (Page(..))

-- MODEL

type alias Model =
    { regCount: Int
    , errorMessage : Maybe String
    }

init =
    ( Model 0 Nothing
    , getMeta
    )

-- UPDATE

type Action
    = GoPage Page
    | CountData (Result Http.Error Int)
    | Reset

update : Action -> Model -> Model
update action model =
    case action of
        GoPage _ ->
            model

        CountData (Result.Ok c) ->
            { model | regCount = c }
        CountData (Result.Err err)->
            { model | errorMessage = Just <| Common.errorHandler err }
        Reset ->
            { model | errorMessage = Nothing }

view : Signal.Address Action -> Model -> Html
view address model =
    nav [ class "navbar navbar-inverse" ]
        [ div
            [ class "container" ]
            [ div [ class "navbar-header" ]
                [ button
                    [ type' "button"
                    , class "navbar-toggle collapsed"
                    , attribute "data-toggle" "collapse"
                    , attribute "data-target" "#navbar"
                    , attribute "aria-expanded" "false"
                    ]
                    [ span [ class "sr-only" ] [ text "Toggle navigation" ]
                    , span [ class "icon-bar" ] []
                    , span [ class "icon-bar" ] []
                    , span [ class "icon-bar" ] []
                    ]
                , a [ class "navbar-brand", href "/", onLinkClick address Reset ]
                    [ text "EU Lobby Register "
                    , span
                        [ class "hidden-xs" ]
                        [ text <| "(" ++ toString model.regCount ++ " entries)"]  -- should include error message
                    ]
                ]
            , div [ class "collapse navbar-collapse", id "navbar" ]
                [ ul [ class "nav navbar-nav navbar-right" ]
                    [ li []
                        [ a [ href "/", onLinkClick address (GoPage (Register Nothing)) ] [ text "Register" ] ]
                    , li []
                        [ a [ href "/recent", onLinkClick address (GoPage <| Register (Just ["recent"])) ] [ text "Recent changes" ] ]
                    , li []
                        [ a
                            [ href "/summary", onLinkClick address (GoPage Summary)
                            -- , class <| if model.page == Summary then "active" else ""
                            ]
                            [ text (toString Summary) ]
                        ]
                    ]
                ]
            ]
        ]

-- TASKS

getMeta : Effects Action
getMeta =
    Http.get ("count" := Json.int) ("/api/register/meta")
        |> Task.toResult
        |> Task.map CountData
        |> Effects.task
