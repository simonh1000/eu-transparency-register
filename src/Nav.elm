module Nav (Action(..), Page(..), update, navbar) where

import Html exposing (..)
import Html.Attributes exposing (class)
import Html.Events exposing (onClick)

import Debug

type Page = Register | Summary
type Action =
      GoRegister
    | GoSummary
    | NoOp (Maybe ())

update : Action -> Page
update action =
    case action of
        GoSummary ->  Summary
        GoRegister -> Register
        -- NoOp -> (Register, updateUrl Register)

navbar : Signal.Address Action -> Html
navbar address =
    nav [ class "row" ]
        [ h1 [ class "col-xs-6" ] [ text "European Lobby Register" ]
        , ul [ class "col-xs-6 menu" ]
            [ li [ onClick address GoRegister ] [ text (toString Register) ]
            , li [ onClick address GoSummary ]  [ text (toString Summary) ]
            ]
        ]