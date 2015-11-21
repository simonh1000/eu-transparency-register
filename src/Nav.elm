module Nav (Model, Page(..), Action(..), init, update, view) where

import Html exposing (..)
import Html.Attributes as Attr exposing (..)
import Html.Events exposing (onClick, onWithOptions)
import Json.Decode as Json
import Json.Encode as JsonE
-- import Debug

-- MODEL

type Page
    = Register
    | Summary
    | Recent

type alias Model =
    { page : Page
    , regCount: String
    }

init p c = { page = p, regCount = c }

-- UPDATE

type Action =
      GoRegister (List String)
    | GoSummary
    -- | GoRecent
    | CountData String
    -- | NoOp (Maybe ())

update : Action -> Model -> Model
update action model =
    case action of
        GoSummary -> { model | page = Summary }
        GoRegister _ -> { model | page = Register }
        -- GoRecent -> { model | page = Recent }
        CountData c -> { model | regCount = c }
        -- NoOp -> (Register, updateUrl Register)

view : Signal.Address Action -> Model -> Html
view address model =
    let
        -- onWithOptions : String -> Options -> Decoder a -> (a -> Message) -> Attribute
        onNavClick act =
            onWithOptions
                "click"
                {stopPropagation=True, preventDefault=True}
                (Json.succeed act)
                (Signal.message address)
    in
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
                , a [ class "navbar-brand", href "/" ]
                    [ text "EU Lobby Register "
                    , span [ class "hidden-xs" ] [ text <| "(" ++ model.regCount ++ " entries)"]
                    ]
                ]
            , div [ class "collapse navbar-collapse", id "navbar" ]
                [ ul [ class "nav navbar-nav navbar-right" ]
                    [ li [] [ a [ href "#", onNavClick (GoRegister []) ] [ text (toString Register) ] ]
                    , li [] [ a [ href "#", onNavClick (GoRegister ["recent"]) ] [ text "Recent changes" ] ]
                    , li [] [ a [ href "#", onNavClick GoSummary ]  [ text (toString Summary) ] ]
                    ]
                ]
            ]
        ]
