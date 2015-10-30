module Nav (Action(..), Page(..), update, navbar) where

import Html exposing (..)
import Html.Attributes exposing (class)
import Html.Events exposing (onClick)

type Page = Register | Summary
type Action = GoRegister | GoSummary

update : Action -> Page
update action =
    case action of
        GoRegister -> Register
        GoSummary -> Summary

navbar : Signal.Address Action -> Html
navbar address =
    nav []
        [ h1 [] [ text "European Lobby Register" ]
        , ul [ class "menu" ]
            [ li [ onClick address GoRegister ] [ text (toString Register) ]
            , li [ onClick address GoSummary ] [ text (toString Summary) ]
            ]
        ]
