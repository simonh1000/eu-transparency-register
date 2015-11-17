module Nav (Model, Page(..), Action(..), init, update, view) where

import Html exposing (..)
import Html.Attributes exposing (class)
import Html.Events exposing (onClick)

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
      GoRegister
    | GoSummary
    | GoRecent
    | CountData String
    | NoOp (Maybe ())

update : Action -> Model -> Model
update action model =
    case action of
        GoSummary -> { model | page <- Summary }
        GoRegister -> { model | page <- Register }
        GoRecent -> { model | page <- Recent }
        CountData c -> { model | regCount <- c }
        -- NoOp -> (Register, updateUrl Register)

view : Signal.Address Action -> Model -> Html
view address model =
    nav [ class "row" ]
        [ h1
            [ class "col-xs-6" ]
            [ text "European Lobby Register "
            , span [] [ text <| "(" ++ model.regCount ++ " entries)"]
            ]
        , ul [ class "col-xs-6 menu" ]
            [ li [ onClick address GoRecent ] [ text (toString Recent) ]
            , li [ onClick address GoRegister ] [ text (toString Register) ]
            , li [ onClick address GoSummary ]  [ text (toString Summary) ]
            ]
        ]
